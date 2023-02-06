package com.example;

import com.google.auto.service.AutoService;
import io.opentelemetry.sdk.autoconfigure.spi.AutoConfigurationCustomizer;
import io.opentelemetry.sdk.autoconfigure.spi.AutoConfigurationCustomizerProvider;
import io.opentelemetry.sdk.autoconfigure.spi.ConfigProperties;
import io.opentelemetry.sdk.trace.SdkTracerProviderBuilder;

/**
 * CacheClientCustomizer implements the {@link AutoConfigurationCustomizerProvider} interface to add a span processor
 * to the configured trace provider.
 */
@AutoService(AutoConfigurationCustomizerProvider.class)
public class CacheClientCustomizer implements AutoConfigurationCustomizerProvider {

    @Override
    public void customize(AutoConfigurationCustomizer customizer) {
        customizer.addTracerProviderCustomizer(this::configureTracerProvider);
    }

    private SdkTracerProviderBuilder configureTracerProvider(SdkTracerProviderBuilder builder,
                                                             ConfigProperties config) {
        return builder.addSpanProcessor(new CacheClientSpanProcessor());
    }
}
