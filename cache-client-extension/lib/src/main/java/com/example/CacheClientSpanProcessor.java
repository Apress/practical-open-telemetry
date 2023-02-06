package com.example;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.context.Context;
import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.trace.ReadWriteSpan;
import io.opentelemetry.sdk.trace.ReadableSpan;
import io.opentelemetry.sdk.trace.SpanProcessor;

import static io.opentelemetry.semconv.trace.attributes.SemanticAttributes.NET_PEER_NAME;

/**
 * CacheClientSpanProcessor implements the {@link SpanProcessor} interface to add a http.is_cache_client attribute when
 * a {@code Span} is started matching a given span kind and net.peer.name. This allows OpenTelemetry Collectors to
 * easily unset the status code for this type of spans if the result is 404.
 *
 * The reason the status of the span cannot be modified within the onEnd() method is that, at this point, the span
 * is finished and cannot be modified. In future releases of OpenTelemetry this may be possible if a beforeEnd() hook
 * is made available (see https://github.com/open-telemetry/opentelemetry-specification/issues/1089).
 */
public class CacheClientSpanProcessor implements SpanProcessor {

  @Override
  public void onStart(Context parentContext, ReadWriteSpan span) {
    // Mark the span as a "cache client" span if it's a client span calling a given service
    if (span.getKind().equals(SpanKind.CLIENT) && "cache-proxy.example.com".equals(span.getAttribute(NET_PEER_NAME))) {
      span.setAttribute(AttributeKey.booleanKey("http.is_cache_client"), true);
    }

    // For demo purposes, we add another custom attribute on every span processed by this processor
    span.setAttribute(AttributeKey.stringKey("custom_processor"), "com.example.Spanprocessor");
  }

  @Override
  public boolean isStartRequired() {
    return true;
  }

  @Override
  public void onEnd(ReadableSpan span) {}

  @Override
  public boolean isEndRequired() {
    return false;
  }

  @Override
  public CompletableResultCode shutdown() {
    return CompletableResultCode.ofSuccess();
  }

  @Override
  public CompletableResultCode forceFlush() {
    return CompletableResultCode.ofSuccess();
  }
}
