import os
import sys
from unittest import mock

from opendm.onnx_providers import get_providers, provider_names


def test_cuda_is_preferred():
    providers = get_providers([
        "CPUExecutionProvider",
        "CoreMLExecutionProvider",
        "CUDAExecutionProvider",
    ])

    assert provider_names(providers) == [
        "CUDAExecutionProvider",
        "CPUExecutionProvider",
    ]


def test_coreml_is_used_on_macos():
    with mock.patch.object(sys, "platform", "darwin"):
        providers = get_providers([
            "CPUExecutionProvider",
            "CoreMLExecutionProvider",
        ])

    assert provider_names(providers) == [
        "CoreMLExecutionProvider",
        "CPUExecutionProvider",
    ]
    assert providers[0][1]["ModelFormat"] == "MLProgram"
    assert providers[0][1]["MLComputeUnits"] == "ALL"
    assert providers[0][1]["RequireStaticInputShapes"] == "1"
    assert providers[0][1]["ModelCacheDirectory"]


def test_gpu_can_be_disabled():
    with mock.patch.dict(os.environ, {"ODM_NO_GPU": "1"}):
        providers = get_providers([
            "CPUExecutionProvider",
            "CoreMLExecutionProvider",
            "CUDAExecutionProvider",
        ])

    assert providers == ["CPUExecutionProvider"]
