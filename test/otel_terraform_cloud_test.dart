// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_terraform_cloud/otel_terraform_cloud.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_terraform_cloud-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('runs.create records CLIENT span', () async {
    await tracedTerraformCloud<String>(
      resource: 'runs',
      action: 'create',
      organization: 'acme',
      workspaceId: 'ws-1',
      invoke: () async => 'run-1',
    );
    final a = attrsOf(spans.findSpanByName('tfc runs.create')!);
    expect(a['tfc.resource'], 'runs');
    expect(a['tfc.organization'], 'acme');
    expect(a['tfc.workspace.id'], 'ws-1');
  });

  test('suppression skips spans', () async {
    await runWithoutTerraformCloudInstrumentationAsync(() async {
      await tracedTerraformCloud<String>(
        resource: 'r',
        action: 'a',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('tfc '), isEmpty);
  });
}
