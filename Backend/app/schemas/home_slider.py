from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HomeSliderCreateIn(BaseModel):
    job_id: str = Field(..., min_length=1)
    image_url: str = Field(..., min_length=1)


class HomeSliderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    job_id: str
    image_url: str
    created_at: datetime
    updated_at: datetime
