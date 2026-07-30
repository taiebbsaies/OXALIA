from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any


class ModelAdapter(ABC):
    """Standardized inference contract.

    Any concrete model (stub today, OXALIA 2D tomorrow) must implement this
    interface. Nothing outside this module should depend on a specific model
    implementation — only on this contract.
    """

    @property
    @abstractmethod
    def model_version(self) -> str:
        """Identifier of the underlying model, included in every result."""

    @abstractmethod
    async def predict(self, image_path: Path) -> dict[str, Any]:
        """Run inference on the image at `image_path`.

        Returns a JSON-serializable dict. The exact schema may evolve as the
        real OXALIA 2D model is integrated — clients should treat it as
        generic/opaque and render it dynamically.
        """
