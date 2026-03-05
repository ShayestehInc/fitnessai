"""
Food lookup service for barcode scanning.
Uses OpenFoodFacts API for product data.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

import requests

logger = logging.getLogger(__name__)

OPENFOODFACTS_API_URL = "https://world.openfoodfacts.org/api/v2/product"


@dataclass(frozen=True)
class FoodLookupResult:
    """Result from a barcode food lookup."""

    barcode: str
    product_name: str
    brand: str
    serving_size: str
    calories: float
    protein: float
    carbs: float
    fat: float
    fiber: float
    sugar: float
    image_url: str
    found: bool


def lookup_barcode(barcode: str) -> FoodLookupResult:
    """
    Look up a food product by barcode using OpenFoodFacts API.

    Args:
        barcode: EAN/UPC barcode string.

    Returns:
        FoodLookupResult with product data or found=False.

    Raises:
        requests.RequestException: If the API call fails.
    """
    if not barcode or not barcode.strip():
        raise ValueError("Barcode cannot be empty")

    url = f"{OPENFOODFACTS_API_URL}/{barcode.strip()}.json"
    response = requests.get(url, timeout=10, headers={"User-Agent": "FitnessAI/1.0"})
    response.raise_for_status()

    data = response.json()
    if data.get("status") != 1:
        return FoodLookupResult(
            barcode=barcode,
            product_name="",
            brand="",
            serving_size="",
            calories=0,
            protein=0,
            carbs=0,
            fat=0,
            fiber=0,
            sugar=0,
            image_url="",
            found=False,
        )

    product = data.get("product", {})
    nutriments = product.get("nutriments", {})

    return FoodLookupResult(
        barcode=barcode,
        product_name=product.get("product_name", "Unknown Product"),
        brand=product.get("brands", ""),
        serving_size=product.get("serving_size", "100g"),
        calories=float(nutriments.get("energy-kcal_100g", 0)),
        protein=float(nutriments.get("proteins_100g", 0)),
        carbs=float(nutriments.get("carbohydrates_100g", 0)),
        fat=float(nutriments.get("fat_100g", 0)),
        fiber=float(nutriments.get("fiber_100g", 0)),
        sugar=float(nutriments.get("sugars_100g", 0)),
        image_url=product.get("image_url", ""),
        found=True,
    )
