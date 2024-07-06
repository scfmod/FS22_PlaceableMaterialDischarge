# Production point discharge

# Table of contents

- [Example](#example)
- [Activation trigger](#activation-trigger)
- [Discharge node](#discharge-node)
- [Discharge info](#discharge-info)
- [Discharge raycast](#discharge-raycast)
- [Discharge effects](#discharge-effects)
- [Discharge animations](#discharge-animations)
- [Discharge sound](#discharge-sound)

Discharge materials from Production Point storage.

## Example
```xml
<?xml version='1.0' encoding='utf-8'?>
<placeable type="...">
    <materialDischarge>
        <activationTrigger node="playerPanelActivationTrigger" />

        <dischargeNodes>
            <productionDischarge node="sideDischargeNode" name="Spillage loction" fillTypes="STONE">
                <effectNodes>
                    <effectNode effectNode="effectNode1" materialType="unloadingSmoke" fadeTime="0.5" />
                    <effectNode effectNode="effectNode2" materialType="unloading" fadeTime="2.5" alignXAxisToWorldY="false" extraDistance="0.2" />
                </effectNodes>
            </productionDischarge>

            <productionDischarge node="frontDischargeNode" name="Dirt output" fillTypes="DIRT">
                <effectNodes>
                    <effectNode effectNode="effectNode3" materialType="unloadingSmoke" fadeTime="0.5" />
                    <effectNode effectNode="effectNode4" materialType="unloading" fadeTime="1.5" alignXAxisToWorldY="false" extraDistance="0.4" />
                    <effectNode effectNode="effectNode5" materialType="unloading" fadeTime="1.9" alignXAxisToWorldY="false" extraDistance="0.4" />
                    <effectNode effectNode="effectNode6" materialType="unloadingSmoke" fadeTime="0.5" />
                </effectNodes>
            </productionDischarge>
        </dischargeNodes>
    </materialDischarge>
</placeable>
```

## Activation trigger

```
placeable.materialSpawner.activationTrigger
```

(Optional)

Player activation trigger for openening the control panel interface. The collisionMask of node must have bit ```20``` (TRIGGER_PLAYER) set in order for it to function.

```xml
...
<materialDischarge>
    <activationTrigger node="playerPanelActivationTrigger" />

    <dischargeNodes>
        ...
    </dischargeNodes>
</materialDischarge>
...
```

### Attributes

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| node | node | No       |         | Trigger node for player activation |



## Discharge node

```
placeable.materialDischarge.dischargeNodes.productionDischarge(%)
```

```xml
...
<materialDischarge>
    <dischargeNodes>
        <productionDischarge node="dischargeLocation" name="$l10n_spillageLocation" fillTypes="STONE IRONORE" />
        ...
    </dischargeNodes>
</materialDischarge>
...
```


### Attributes

| Name                           | Type    | Required | Default              | Description     |
|--------------------------------|---------|----------|----------------------|-----------------|
| node                           | node    | **Yes**  |                      | Discharge node. |
| fillTypes                      | string  | **Yes**  |                      | One or more available fill types, separated by whitespace. |
| name                           | string  | No       | ```Output #```       | Name to display in in-game control panel interface, supports I18N locale syntax. |
| emptySpeed                     | int     | No       | ```250```            | Empty speed in l/sec. |
| stopDischargeIfNotActive       | boolean | No       | ```true```           | Stop discharge when there are no active productions. |
| stopDischargeIfNotRunning      | boolean | No       |```false```           | Stop discharge when there are no running productions. |
| stopDischargeIfNotPossible     | boolean | No       | ```false```          | Stop discharge if not possible. |
| effectTurnOffThreshold         | float   | No       | ```0.25```           | After this time has passed and nothing has been discharged, the effects are turned off. |
| maxDistance                    | float   | No       | ```10```             | Max discharge distance. |
| soundNode                      | node    | No       | ```Discharge node``` | Sound link node. |
| playSound                      | boolean | No       | ```true```           | Play discharge sound. |
| defaultEnabled                 | boolean | No       | ```true```           | Set whether discharge is enabled or not by default. |
| defaultCanDischargeToGround    | boolean | No       | ```true```           | Default value for "can discharge to ground" setting. |
| defaultCanDischargeToObject    | boolean | No       | ```true```           | Default value for "can discharge to objects" setting. |
| defaultCanDischargeToAnyObject | boolean | No       | ```false```          | Default value for "can discharge to any objects" setting. |

## Discharge info

```
placeable.materialDischarge.dischargeNodes.productionDischarge(%).info
```

(Optional)

```xml
...
<materialDischarge>
    <dischargeNodes>
        <productionDischarge node="dischargeLocation" name="Spillage loction" fillTypes="TAILINGS">
            ...
            <info width="0.5" length="0.5" />
            ...
        </productionDischarge>
    </dischargeNodes>
</materialDischarge>
...
```


### Attributes
| Name                  | Type    | Required | Default              | Description         |
|-----------------------|---------|----------|----------------------|---------------------|
| node                  | node    | No       | ```Discharge node``` | Discharge info node |
| width                 | float   | No       | ```1```              | Discharge info width |
| length                | float   | No       |```1```               | Discharge info length |
| zOffset               | float   | No       |```0```               | Discharge info Z axis offset |
| yOffset               | float   | No       | ```0```              | Discharge info Y axis offset |
| limitToGround         | boolean | No       | ```true```           | Discharge info is limited to ground |
| useRaycastHitPosition | boolean | No       | ```false```          | Discharge info uses raycast hit position |

## Discharge raycast

```
placeable.materialDischarge.dischargeNodes.productionDischarge(%).raycast
```

(Optional)

```xml
...
<materialDischarge>
    <dischargeNodes>
        <productionDischarge node="dischargeLocation" name="Spillage loction" fillTypes="TAILINGS">
            ...
            <raycast maxDistance="20" yOffset="0.8" />
            ...
        </productionDischarge>
    </dischargeNodes>
</materialDischarge>
...
```

### Attributes
| Name                  | Type    | Required | Default              | Description  |
|-----------------------|---------|----------|----------------------|--------------|
| node                  | node    | No       | ```Discharge node``` | Raycast node |
| yOffset               | float   | No       | ```0```              | Y offset |
| maxDistance           | float   | No       | ```10```             | Raycast max distance |
| useWorldNegYDirection | boolean | No       | ```true```           | Use world negative Y Direction |

## Discharge effects

```
placeable.materialDischarge.dischargeNodes.productionDischarge(%).effectNodes.effectNode(%)
```

(Optional)

```xml
...
<materialDischarge>
    <dischargeNodes>
        <productionDischarge node="dischargeLocation" name="Spillage loction" fillTypes="TAILINGS">
            ...
            <effectNodes>
                <effectNode effectNode="effectSmoke" materialType="unloadingSmoke" fadeTime="0.5" />
            </effectNodes>
            ...
        </productionDischarge>
    </dischargeNodes>
</materialDischarge>
...
```

Uses the standard effect nodes setup.

## Discharge animations

```
placeable.materialDischarge.dischargeNodes.productionDischarge(%).animationNodes.animationNode(%)
```
(Optional)

```xml
...
<materialDischarge>
    <dischargeNodes>
        <productionDischarge node="dischargeLocation" name="Spillage loction" fillTypes="TAILINGS">
            ...
            <animationNodes>
                <animationNode class="ScrollingAnimation" node="belt" rotSpeed="-20" rotAxis="1" shaderComponentScale="-1 0 0 0" scrollSpeed="0.5" shaderParameterName="offsetUV" />
            </animationNodes>
            ...
        </productionDischarge>
    </dischargeNodes>
</materialDischarge>
...
```

Uses the standard effect nodes setup.

## Discharge sound

```
placeable.materialDischarge.dischargeNodes.productionDischarge(%).dischargeStateSound(%)
```

(Optional)

Uses the standard sample setup.

```xml
...
<materialDischarge>
    <dischargeNodes>
        <productionDischarge node="dischargeLocation" name="Spillage loction" fillTypes="TAILINGS">
            ...
            <dischargeStateSound template="augerBelt" pitchScale="0.7" volumeScale="1.4" fadeIn="0.2" fadeOut="1" innerRadius="1.0" outerRadius="40.0" linkNode="belt" />
            <dischargeStateSound template="dischargeLoop" pitchScale="1.0" volumeScale="0.7" fadeIn="0.5" fadeOut="1.7"/>
            ...
        </productionDischarge>
    </dischargeNodes>
</materialDischarge>
...
```