import {
  Button,
  ByondUi,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FiringMode = 'direct' | 'predictive' | 'mixed';

const firingModes: { id: FiringMode; label: string; tooltip: string }[] = [
  {
    id: 'direct',
    label: 'Direct',
    tooltip: "Aim at the target's current position",
  },
  {
    id: 'predictive',
    label: 'Predictive',
    tooltip: 'Lead consistently moving targets',
  },
  {
    id: 'mixed',
    label: 'Mixed',
    tooltip:
      'Choose direct or predictive aim independently for each projectile',
  },
];

type Turret = {
  ref: string;
  name: string;
  powered: BooleanLike;
  automatic: BooleanLike;
  configured: BooleanLike;
  clearable: BooleanLike;
  sameZ: BooleanLike;
  range: number;
  supportsFiringModes: BooleanLike;
  firingMode: FiringMode;
};

type Data = {
  mapRef: string;
  selected: string | null;
  turrets: Turret[];
};

export const HullDefenseControl = () => {
  const { act, data } = useBackend<Data>();
  const turrets = data.turrets || [];
  const selected = turrets.find((turret) => turret.ref === data.selected);
  const selectedIndex = turrets.findIndex(
    (turret) => turret.ref === data.selected,
  );
  const previousTurret =
    selectedIndex >= 0 && turrets.length > 1
      ? turrets[(selectedIndex - 1 + turrets.length) % turrets.length]
      : undefined;
  const nextTurret =
    selectedIndex >= 0 && turrets.length > 1
      ? turrets[(selectedIndex + 1) % turrets.length]
      : undefined;

  return (
    <Window width={1050} height={600} title="Hull-Defense Control">
      <Window.Content>
        <Stack fill>
          <Stack.Item basis="42%">
            <Section fill scrollable title="Linked Turrets">
              {turrets.length ? (
                <Table>
                  {turrets.map((turret, index) => (
                    <Table.Row key={turret.ref} className="candystripe">
                      <Table.Cell>
                        <Button
                          fluid
                          selected={turret.ref === data.selected}
                          onClick={() => act('select', { ref: turret.ref })}
                        >
                          {turret.name}
                        </Button>
                      </Table.Cell>
                      <Table.Cell collapsing>
                        {turret.powered ? 'Online' : 'Offline'}
                      </Table.Cell>
                      <Table.Cell collapsing>{turret.range} tiles</Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          icon="arrow-up"
                          disabled={index === 0}
                          tooltip="Move turret earlier in the control order"
                          onClick={() => act('move_up', { ref: turret.ref })}
                        />
                      </Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          icon="arrow-down"
                          disabled={index === turrets.length - 1}
                          tooltip="Move turret later in the control order"
                          onClick={() =>
                            act('move_down', { ref: turret.ref })
                          }
                        />
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              ) : (
                <NoticeBox>No turrets linked.</NoticeBox>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section
              fill
              title={selected ? selected.name : 'Turret Preview'}
              buttons={
                selected && (
                  <>
                    <Button
                      icon="gamepad"
                      disabled={!selected.powered || !selected.sameZ}
                      onClick={() => act('control', { ref: selected.ref })}
                    >
                      Assume control
                    </Button>
                    <Button
                      icon="robot"
                      selected={selected.automatic}
                      disabled={!selected.configured && !selected.automatic}
                      onClick={() => act('automatic', { ref: selected.ref })}
                    >
                      Automatic
                    </Button>
                    {!!selected.clearable && (
                      <Button.Confirm
                        color="orange"
                        confirmContent="Clear authorization?"
                        icon="id-card"
                        onClick={() =>
                          act('clear_faction', { ref: selected.ref })
                        }
                      >
                        Clear faction
                      </Button.Confirm>
                    )}
                    <Button
                      color="bad"
                      icon="unlink"
                      onClick={() => act('unlink', { ref: selected.ref })}
                    >
                      Unlink
                    </Button>
                  </>
                )
              }
            >
              <Stack fill vertical>
                <Stack.Item>
                  <Stack>
                    <Stack.Item grow>
                      {selected && !selected.sameZ ? (
                        <NoticeBox danger>
                          Turret is on a different Z-level
                        </NoticeBox>
                      ) : selected?.powered ? (
                        <NoticeBox info>
                          {`${selected.configured ? 'Authorized' : 'Unconfigured'} - automatic mode ${selected.automatic ? 'enabled' : 'disabled'}`}
                        </NoticeBox>
                      ) : selected ? (
                        <NoticeBox danger>No input signal</NoticeBox>
                      ) : (
                        <NoticeBox>
                          Select a linked turret to preview it.
                        </NoticeBox>
                      )}
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="chevron-left"
                        disabled={!previousTurret}
                        tooltip="Previous turret"
                        onClick={() =>
                          previousTurret &&
                          act('select', { ref: previousTurret.ref })
                        }
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="chevron-right"
                        disabled={!nextTurret}
                        tooltip="Next turret"
                        onClick={() =>
                          nextTurret && act('select', { ref: nextTurret.ref })
                        }
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                {selected && (
                  <Stack.Item>
                    <LabeledList>
                      <LabeledList.Item label="Automatic fire mode">
                        {selected.supportsFiringModes ? (
                          firingModes.map((mode) => (
                            <Button
                              key={mode.id}
                              selected={selected.firingMode === mode.id}
                              tooltip={mode.tooltip}
                              onClick={() =>
                                act('firing_mode', {
                                  ref: selected.ref,
                                  mode: mode.id,
                                })
                              }
                            >
                              {mode.label}
                            </Button>
                          ))
                        ) : (
                          <Button
                            selected
                            disabled
                            tooltip="Legacy turrets use direct fire only"
                          >
                            Direct (fixed)
                          </Button>
                        )}
                      </LabeledList.Item>
                    </LabeledList>
                  </Stack.Item>
                )}
                <Stack.Item grow>
                  {selected && (
                    <ByondUi
                      height="100%"
                      width="100%"
                      params={{ id: data.mapRef, type: 'map' }}
                    />
                  )}
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
