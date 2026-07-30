import asyncio
import random
from pathlib import Path
from typing import Any

from app.core.model_adapter import ModelAdapter


class StubModelAdapter(ModelAdapter):
    """Placeholder adapter simulating inference latency and a plausible output.

    Swappable later with a real TorchXRayVision / OXALIA 2D adapter without
    touching routers, services, or the mobile app contract.
    """

    _VERSION = "stub-0.1.0"

    @property
    def model_version(self) -> str:
        return self._VERSION

    async def predict(self, image_path: Path) -> dict[str, Any]:
        await asyncio.sleep(1.5)  # simulate model latency

        findings = ["Cardiomegaly", "Effusion", "No Finding", "Pneumonia"]
        return {
            "model_version": self.model_version,
            "findings": [
                {"label": label, "probability": round(random.uniform(0.05, 0.95), 3)}
                for label in findings
            ],
            "processed_file": image_path.name,
        }
