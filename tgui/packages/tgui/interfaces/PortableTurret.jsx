import { Button, LabeledList, NoticeBox, Section } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const firingModes = [
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

export const PortableTurret = (props) => {
  const { act, data } = useBackend();
  const {
    silicon_user,
    locked,
    on,
    check_weapons,
    neutralize_criminals,
    neutralize_all,
    neutralize_unidentified,
    neutralize_nonmindshielded,
    neutralize_cyborgs,
    neutralize_heads,
    manual_control,
    allow_manual_control,
    lasertag_turret,
    faction_name,
    supports_faction_configuration,
    faction_configured,
    supports_firing_modes,
    firing_mode,
  } = data;
  return (
    <Window
      width={340}
      height={lasertag_turret ? 155 : supports_firing_modes ? 370 : 337}
    >
      <Window.Content>
        <NoticeBox>
          Swipe an ID card to {locked ? 'unlock' : 'lock'} this interface.
        </NoticeBox>

        <Section>
          <LabeledList>
            <LabeledList.Item
              label="Status"
              buttons={
                !lasertag_turret &&
                (!!allow_manual_control ||
                  (!!manual_control && !!silicon_user)) && (
                  <Button
                    icon={manual_control ? 'wifi' : 'terminal'}
                    content={
                      manual_control ? 'Remotely Controlled' : 'Manual Control'
                    }
                    disabled={manual_control}
                    color="bad"
                    onClick={() => act('manual')}
                  />
                )
              }
            >
              <Button
                icon={on ? 'power-off' : 'times'}
                content={on ? 'On' : 'Off'}
                selected={on}
                disabled={locked}
                onClick={() => act('power')}
              />
            </LabeledList.Item>
            <LabeledList.Item
              label="Faction"
              buttons={
                !!supports_faction_configuration &&
                !faction_configured && (
                  <Button
                    icon="id-card"
                    content="Swipe Held ID"
                    disabled={locked}
                    tooltip="Hold an Expedition or Syndicate ID in your active hand"
                    onClick={() => act('setfaction')}
                  />
                )
              }
            >
              {faction_name}
            </LabeledList.Item>
            {!!supports_firing_modes && (
              <LabeledList.Item label="Fire Mode">
                {firingModes.map((mode) => (
                  <Button
                    key={mode.id}
                    compact
                    selected={firing_mode === mode.id}
                    disabled={locked}
                    tooltip={mode.tooltip}
                    onClick={() => act('firing_mode', { mode: mode.id })}
                  >
                    {mode.label}
                  </Button>
                ))}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        {!lasertag_turret && (
          <Section
            title="Target Settings"
            buttons={
              <Button.Checkbox
                checked={!neutralize_heads}
                content="Ignore Command"
                disabled={locked}
                onClick={() => act('shootheads')}
              />
            }
          >
            <Button.Checkbox
              fluid
              checked={neutralize_all}
              content="Non-Security and Non-Command"
              disabled={locked}
              onClick={() => act('shootall')}
            />
            <Button.Checkbox
              fluid
              checked={check_weapons}
              content="Unauthorized Weapons"
              disabled={locked}
              onClick={() => act('authweapon')}
            />
            <Button.Checkbox
              fluid
              checked={neutralize_unidentified}
              content="Unidentified Life Signs"
              disabled={locked}
              onClick={() => act('checkxenos')}
            />
            <Button.Checkbox
              fluid
              checked={neutralize_nonmindshielded}
              content="Non-Mindshielded"
              disabled={locked}
              onClick={() => act('checkloyal')}
            />
            <Button.Checkbox
              fluid
              checked={neutralize_criminals}
              content="Wanted Criminals"
              disabled={locked}
              onClick={() => act('shootcriminals')}
            />
            <Button.Checkbox
              fluid
              checked={neutralize_cyborgs}
              content="Cyborgs"
              disabled={locked}
              onClick={() => act('shootborgs')}
            />
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
