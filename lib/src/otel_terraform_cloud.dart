// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_terraform_cloud_suppression.dart';

const _tracerName = 'dartastic_otel_libs_terraform_cloud';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Terraform Cloud / HCP Terraform API call in a CLIENT
/// span. [resource] is one of `workspaces`, `runs`, `state_versions`,
/// `policies`; [action] is `create`, `apply`, `cancel`, etc.
Future<T> tracedTerraformCloud<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? organization,
  String? workspaceId,
  String? runId,
}) async {
  if (terraformCloudInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'tfc.resource': resource,
    'tfc.action': action,
    'tfc.operation': '$resource.$action',
  };
  if (organization != null) m['tfc.organization'] = organization;
  if (workspaceId != null) m['tfc.workspace.id'] = workspaceId;
  if (runId != null) m['tfc.run.id'] = runId;

  final span = _tracer().startSpan(
    'tfc $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
