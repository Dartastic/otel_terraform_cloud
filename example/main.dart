// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_terraform_cloud/otel_terraform_cloud.dart';

/// Traces Terraform Cloud / HCP Terraform calls with OpenTelemetry.
///
/// `otel_terraform_cloud` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Terraform Cloud / HCP Terraform call in
/// [tracedTerraformCloud]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'terraform-cloud-example');

  // Wraps a Terraform Cloud / HCP Terraform API call in a CLIENT span.
  final terraformCloudId = await tracedTerraformCloud<String>(
    resource: 'workspaces',
    action: 'create',
    organization: 'example',
    workspaceId: 'workspace_8f3a2c',
    runId: 'run_8f3a2c',
    invoke: () async {
      // Make the Terraform Cloud / HCP Terraform call here, then report what it returned.
      return 'terraform_cloud_8f3a2c';
    },
  );
  OTelLog.info('tracedTerraformCloud returned $terraformCloudId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutTerraformCloudInstrumentationAsync.
  await runWithoutTerraformCloudInstrumentationAsync(
    () => tracedTerraformCloud<String>(
      resource: 'workspaces',
      action: 'create',
      organization: 'example',
      workspaceId: 'workspace_8f3a2c',
      runId: 'run_8f3a2c',
      invoke: () async {
        return 'terraform_cloud_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
