#!/usr/bin/env bash
set -euo pipefail

target_namespace="${K8S_NAMESPACE}"
chart_dir="helm-chart"
stage_values_file="${chart_dir}/values-${STAGE}.yaml"

app_host_name="${APP_HOST_NAME}"
release_name_source="${APP_NAME}-${STAGE}"
release_name="$(tr '[:upper:]' '[:lower:]' <<<"${release_name_source}" | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
release_name="${release_name:0:53}"
release_name="$(sed -E 's/-+$//' <<<"${release_name}")"

if [[ -z "${release_name}" ]]; then
	echo "APP_NAME and STAGE must produce a non-empty Helm release name after sanitization" >&2
	exit 1
fi

helm_args=(
	--namespace "${target_namespace}"
	--wait
	--atomic
	-f "${chart_dir}/values.yaml"
	--set "image.repository=${IMAGE_REPOSITORY}"
	--set "image.digest=${IMAGE_DIGEST}"
	--set "appVersion=${GIT_SHA}"
	--set "ingress.hostname=${app_host_name}"
)

if [[ -f "${stage_values_file}" ]]; then
  echo "Using environment specific file ${stage_values_file}"
	helm_args+=(-f "${stage_values_file}")
fi

echo "Running helm upgrade --install for app version ${GIT_SHA}"
lock_error="another operation (install/upgrade/rollback) is in progress"
retry_interval_seconds=15
retry_deadline_seconds=$(($(date +%s) + 300))

while true; do
	helm_stderr_file="$(mktemp)"
	set +e
	set -x
	helm upgrade --install "${helm_args[@]}" "${release_name}" "${chart_dir}" \
		1>/dev/stderr \
		2> >(tee /dev/stderr "${helm_stderr_file}" >/dev/null)
	helm_exit_code=$?
	set +x
	set -e
	helm_stderr="$(cat "${helm_stderr_file}")"
	rm -f "${helm_stderr_file}"

	if [[ "${helm_exit_code}" -eq 0 ]]; then
		break
	fi

	if grep -Fq "${lock_error}" <<<"${helm_stderr}"; then
		if [[ "$(date +%s)" -ge "${retry_deadline_seconds}" ]]; then
			echo "Timed out waiting for ongoing Helm operation to finish after 5 minutes." >&2
			exit "${helm_exit_code}"
		fi

		echo "Helm release operation already in progress. Retrying in ${retry_interval_seconds}s..." >&2
		sleep "${retry_interval_seconds}"
		continue
	fi

	exit "${helm_exit_code}"
done
