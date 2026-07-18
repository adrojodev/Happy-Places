#!/usr/bin/env python3
"""Resubmit a rejected App Store version with a new build.

Runs in CI (resubmit.yml) with the ASC_* secrets. Steps:
  1. Find the build for BUILD_NUMBER and answer export compliance the same
     way as every release (standard HTTPS only -> usesNonExemptEncryption=false).
  2. Attach that build to the app version APP_VERSION.
  3. Resubmit the app's open review submission (the one App Review rejected).

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, APP_ID, APP_VERSION, BUILD_NUMBER.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt  # PyJWT

BASE = "https://api.appstoreconnect.apple.com"
APP_ID = os.environ["APP_ID"]
APP_VERSION = os.environ["APP_VERSION"]
BUILD_NUMBER = os.environ["BUILD_NUMBER"]


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1140,
         "aud": "appstoreconnect-v1"},
        os.environ["ASC_KEY_P8"],
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"]},
    )


def call(method: str, path: str, body: dict | None = None) -> dict:
    req = urllib.request.Request(
        BASE + path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {token()}",
                 "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        print(f"::error::{method} {path} -> HTTP {e.code}: {detail}")
        raise


def diagnose(sub_id: str, version_id: str) -> None:
    """Print read-only state that may explain a submit refusal."""
    for label, path in [
        ("submission items", f"/v1/reviewSubmissions/{sub_id}/items"),
        ("age rating declaration",
         f"/v1/appStoreVersions/{version_id}/ageRatingDeclaration"),
        ("review detail",
         f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail"),
        ("version attributes", f"/v1/appStoreVersions/{version_id}"),
    ]:
        try:
            data = call("GET", path)
            print(f"--- {label}: {json.dumps(data.get('data'), indent=1)}")
        except urllib.error.HTTPError:
            print(f"--- {label}: <request failed>")


def main() -> None:
    # 1. The build, plus export compliance.
    builds = call("GET", f"/v1/builds?filter[app]={APP_ID}"
                         f"&filter[version]={BUILD_NUMBER}"
                         f"&filter[preReleaseVersion.version]={APP_VERSION}")
    if not builds["data"]:
        sys.exit(f"No build {BUILD_NUMBER} for version {APP_VERSION} found")
    build = builds["data"][0]
    build_id = build["id"]
    compliance = build["attributes"]["usesNonExemptEncryption"]
    print(f"Build {BUILD_NUMBER}: id={build_id} "
          f"state={build['attributes']['processingState']} "
          f"usesNonExemptEncryption={compliance}")
    if compliance is None:
        call("PATCH", f"/v1/builds/{build_id}",
             {"data": {"type": "builds", "id": build_id,
                       "attributes": {"usesNonExemptEncryption": False}}})
        print("Export compliance answered: usesNonExemptEncryption=false")

    # 2. Attach the build to the version.
    versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions"
                           f"?filter[versionString]={APP_VERSION}")
    if not versions["data"]:
        sys.exit(f"App version {APP_VERSION} not found")
    version = versions["data"][0]
    version_id = version["id"]
    print(f"Version {APP_VERSION}: id={version_id} "
          f"state={version['attributes']['appStoreState']}")
    call("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build",
         {"data": {"type": "builds", "id": build_id}})
    attached = call("GET", f"/v1/appStoreVersions/{version_id}/build")
    attached_no = attached["data"]["attributes"]["version"]
    print(f"Attached build is now: {attached_no}")
    if attached_no != BUILD_NUMBER:
        sys.exit("Build attach did not stick")

    # 3. Resubmit the open review submission.
    subs = call("GET", f"/v1/reviewSubmissions?filter[app]={APP_ID}"
                       f"&filter[state]=UNRESOLVED_ISSUES,READY_FOR_REVIEW"
                       f"&filter[platform]=IOS")
    if not subs["data"]:
        sys.exit("No open review submission found — nothing to resubmit")
    sub = subs["data"][0]
    sub_id = sub["id"]
    print(f"Review submission: id={sub_id} "
          f"state={sub['attributes']['state']}")
    # Right after a build swap ASC briefly reports the version as not ready
    # to submit; retry until it settles.
    for attempt in range(10):
        try:
            call("PATCH", f"/v1/reviewSubmissions/{sub_id}",
                 {"data": {"type": "reviewSubmissions", "id": sub_id,
                           "attributes": {"submitted": True}}})
            break
        except urllib.error.HTTPError as e:
            if e.code == 409 and attempt < 9:
                print(f"Not ready yet (attempt {attempt + 1}/10), "
                      f"retrying in 60s...")
                time.sleep(60)
            else:
                diagnose(sub_id, version_id)
                raise
    final = call("GET", f"/v1/reviewSubmissions/{sub_id}")
    print(f"Submission state after resubmit: "
          f"{final['data']['attributes']['state']}")


if __name__ == "__main__":
    main()
