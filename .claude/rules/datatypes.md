# Data types rules
- For api responses, always use rest_framework_dataclasses, not normal serializer
- for services and utils, return dataclass or pydandict models, never ever return dict