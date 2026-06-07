import os
import sys

import onnxruntime as ort

from opendm import log


COREML_COMPUTE_UNITS = {
    "ALL",
    "CPUOnly",
    "CPUAndGPU",
    "CPUAndNeuralEngine",
}


def _gpu_disabled():
    return bool(os.environ.get("ODM_NO_GPU"))


def _coreml_cache_dir():
    configured_dir = os.environ.get("ODX_COREML_CACHE_DIR")
    if configured_dir:
        return os.path.abspath(os.path.expanduser(configured_dir))

    return os.path.abspath(os.path.join(
        os.path.dirname(__file__),
        "..",
        "storage",
        "models",
        "coreml-cache",
    ))


def get_providers(available_providers=None):
    available = set(
        available_providers
        if available_providers is not None
        else ort.get_available_providers()
    )

    if not _gpu_disabled() and "CUDAExecutionProvider" in available:
        return ["CUDAExecutionProvider", "CPUExecutionProvider"]

    if (
        not _gpu_disabled()
        and sys.platform == "darwin"
        and "CoreMLExecutionProvider" in available
    ):
        compute_units = os.environ.get(
            "ODX_COREML_COMPUTE_UNITS",
            "ALL",
        )
        if compute_units not in COREML_COMPUTE_UNITS:
            log.WARNING(
                "Invalid ODX_COREML_COMPUTE_UNITS value %s; using ALL"
                % compute_units
            )
            compute_units = "ALL"

        provider_options = {
            "ModelFormat": "MLProgram",
            "MLComputeUnits": compute_units,
            "RequireStaticInputShapes": "1",
            "EnableOnSubgraphs": "0",
            "ModelCacheDirectory": _coreml_cache_dir(),
            "SpecializationStrategy": "FastPrediction",
        }

        if os.environ.get("ODX_COREML_PROFILE") == "1":
            provider_options["ProfileComputePlan"] = "1"

        return [
            ("CoreMLExecutionProvider", provider_options),
            "CPUExecutionProvider",
        ]

    return ["CPUExecutionProvider"]


def provider_names(providers):
    return [
        provider[0] if isinstance(provider, tuple) else provider
        for provider in providers
    ]


def create_inference_session(model):
    providers = get_providers()
    log.INFO(" ?> Using providers %s" % ", ".join(provider_names(providers)))

    try:
        return ort.InferenceSession(model, providers=providers)
    except Exception as error:
        if provider_names(providers) == ["CPUExecutionProvider"]:
            raise

        log.WARNING(
            "ONNX accelerator initialization failed (%s); falling back to CPU"
            % error
        )
        return ort.InferenceSession(
            model,
            providers=["CPUExecutionProvider"],
        )
