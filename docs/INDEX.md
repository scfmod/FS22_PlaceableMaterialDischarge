# Documentation

# Table of Contents

- [Add specialization to placeable type](#add-specialization-to-placeable-type)
- [Placeable XML](#placeable-xml)
- [Discharge from Production Point storage](#discharge-from-production-point-storage)
- [Discharge spawned materials](#discharge-spawned-materials)

Documentation files:
- 🗎 [XSD validation schema](./schema/placeable_materialDischarge.xsd)
- 🗎 [HTML schema](./schema/placeable_materialDischarge.html)

## Add specialization to placeable type

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc version="...">
    ...
    <placeableTypes>
        <!-- Extend parent type, can be anything -->
        <type name="washPlant" parent="simplePlaceable" filename="$dataS/scripts/placeables/Placeable.lua">
            <specialization name="FS22_1_PlaceableMaterialDischarge.materialProcessor" />
        </type>
    </placeableTypes>
    ...
</modDesc>
```

## Discharge from Production Point storage

Discharge specified fill type(s) from production point. [Read more here.](./PRODUCTION.md)

## Discharge spawned materials

Generate fill type(s) and discharge. [Read more here.](./SPAWN.md)