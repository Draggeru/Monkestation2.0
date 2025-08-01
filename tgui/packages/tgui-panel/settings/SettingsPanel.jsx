/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { toFixed } from 'common/math';
import { capitalize } from 'common/string';
import { useLocalState } from 'tgui/backend';
import { useDispatch, useSelector } from 'common/redux';
import {
  Box,
  Button,
  Collapsible,
  ColorBox,
  Divider,
  Icon,
  Input,
  LabeledList,
  Section,
  Stack,
  Tabs,
  TextArea,
  Slider,
  NoticeBox,
} from 'tgui/components';
import { ChatPageSettings } from '../chat';
import { clearChat, rebuildChat, saveChatToDisk } from '../chat/actions';
import { THEMES } from '../themes';
import {
  changeSettingsTab,
  exportSettings,
  updateSettings,
  addHighlightSetting,
  removeHighlightSetting,
  updateHighlightSetting,
} from './actions';
import { SETTINGS_TABS, FONTS, WARN_AFTER_HIGHLIGHT_AMT } from './constants';
import { setEditPaneSplitters } from './scaling';
import {
  selectActiveTab,
  selectSettings,
  selectHighlightSettings,
  selectHighlightSettingById,
} from './selectors';
import { importChatSettings } from './settingsImExport';
import { reconnectWebsocket, disconnectWebsocket } from '../websocket';
import { chatRenderer } from '../chat/renderer';

export const SettingsPanel = (props, context) => {
  const activeTab = useSelector(context, selectActiveTab);
  const dispatch = useDispatch(context);
  return (
    <Stack fill>
      <Stack.Item>
        <Section fitted fill minHeight="8em">
          <Tabs vertical>
            {SETTINGS_TABS.map((tab) => (
              <Tabs.Tab
                key={tab.id}
                selected={tab.id === activeTab}
                onClick={() =>
                  dispatch(
                    changeSettingsTab({
                      tabId: tab.id,
                    }),
                  )
                }
              >
                {tab.name}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Section>
      </Stack.Item>
      <Stack.Item grow={1} basis={0}>
        {activeTab === 'general' && <SettingsGeneral />}
        {activeTab === 'chatPage' && <ChatPageSettings />}
        {activeTab === 'textHighlight' && <TextHighlightSettings />}
        {activeTab === 'statPanel' && <SettingsStatPanel />}
        {activeTab === 'experimental' && <ExperimentalSettings />}
      </Stack.Item>
    </Stack>
  );
};

export const SettingsGeneral = (props, context) => {
  const { theme, fontFamily, coloredNames, fontSize, lineHeight } = useSelector(
    context,
    selectSettings,
  );
  const dispatch = useDispatch(context);
  const [freeFont, setFreeFont] = useLocalState('freeFont', false);
  const [editingPanes, setEditingPanes] = useLocalState('freeFont', false);

  return (
    <Section>
      <LabeledList>
        <LabeledList.Item label="Theme">
          {THEMES.map((THEME) => (
            <Button
              key={THEME}
              content={capitalize(THEME)}
              selected={theme === THEME}
              color="transparent"
              onClick={() =>
                dispatch(
                  updateSettings({
                    theme: THEME,
                  }),
                )
              }
            />
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="UI sizes">
          <Button
            onClick={() =>
              setEditingPanes((val) => {
                setEditPaneSplitters(!val);
                return !val;
              })
            }
            color={editingPanes ? 'red' : undefined}
            icon={editingPanes ? 'save' : undefined}
          >
            {editingPanes ? 'Save' : 'Adjust UI Sizes'}
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Font style">
          <Stack.Item>
            {(!freeFont && (
              <Collapsible
                title={fontFamily}
                width={'100%'}
                buttons={
                  <Button
                    content="Custom font"
                    icon={freeFont ? 'lock-open' : 'lock'}
                    color={freeFont ? 'good' : 'bad'}
                    onClick={() => {
                      setFreeFont(!freeFont);
                    }}
                  />
                }
              >
                {FONTS.map((FONT) => (
                  <Button
                    key={FONT}
                    content={FONT}
                    fontFamily={FONT}
                    selected={fontFamily === FONT}
                    color="transparent"
                    onClick={() =>
                      dispatch(
                        updateSettings({
                          fontFamily: FONT,
                        }),
                      )
                    }
                  />
                ))}
              </Collapsible>
            )) || (
              <Stack>
                <Input
                  width={'100%'}
                  value={fontFamily}
                  onChange={(e, value) =>
                    dispatch(
                      updateSettings({
                        fontFamily: value,
                      }),
                    )
                  }
                />
                <Button
                  ml={0.5}
                  content="Custom font"
                  icon={freeFont ? 'lock-open' : 'lock'}
                  color={freeFont ? 'good' : 'bad'}
                  onClick={() => {
                    setFreeFont(!freeFont);
                  }}
                />
              </Stack>
            )}
          </Stack.Item>
        </LabeledList.Item>
        <LabeledList.Item label="High Contrast">
          <Button.Checkbox
            content="Colored Names"
            checked={coloredNames}
            onClick={() =>
              dispatch(
                updateSettings({
                  coloredNames: !coloredNames,
                }),
              )
            }
          />
        </LabeledList.Item>
        <LabeledList.Item label="Font size" verticalAlign="middle">
          <Stack textAlign="center">
            <Stack.Item grow>
              <Slider
                width="100%"
                step={1}
                stepPixelSize={20}
                minValue={8}
                maxValue={32}
                value={fontSize}
                unit="px"
                format={(value) => toFixed(value)}
                onChange={(e, value) =>
                  dispatch(updateSettings({ fontSize: value }))
                }
              />
            </Stack.Item>
          </Stack>
        </LabeledList.Item>
        <LabeledList.Item label="Line height">
          <Slider
            width="100%"
            step={0.01}
            stepPixelSize={2}
            minValue={0.8}
            maxValue={5}
            value={lineHeight}
            format={(value) => toFixed(value, 2)}
            onDrag={(e, value) =>
              dispatch(
                updateSettings({
                  lineHeight: value,
                }),
              )
            }
          />
        </LabeledList.Item>
      </LabeledList>
      <Divider />
      <Stack fill>
        <Stack.Item mt={0.15}>
          <Button
            icon="compact-disc"
            tooltip="Export chat settings"
            onClick={() => dispatch(exportSettings())}
          >
            Export settings
          </Button>
        </Stack.Item>
        <Stack.Item mt={0.15}>
          <Button.File
            accept=".json"
            tooltip="Import chat settings"
            icon="arrow-up-from-bracket"
            onSelectFiles={(files) => importChatSettings(dispatch, files)}
          >
            Import settings
          </Button.File>
        </Stack.Item>
        <Stack.Item grow mt={0.15}>
          <Button
            content="Save chat log"
            icon="save"
            tooltip="Export current tab history into HTML file"
            onClick={() => dispatch(saveChatToDisk())}
          />
        </Stack.Item>
        <Stack.Item mt={0.15}>
          <Button.Confirm
            content="Clear chat"
            icon="trash"
            tooltip="Erase current tab history"
            onClick={() => dispatch(clearChat())}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const TextHighlightSettings = (props, context) => {
  const highlightSettings = useSelector(context, selectHighlightSettings);
  const dispatch = useDispatch(context);
  return (
    <Section fill scrollable height="250px">
      <Stack vertical>
        {highlightSettings.map((id, i) => (
          <TextHighlightSetting
            key={i}
            id={id}
            mb={i + 1 === highlightSettings.length ? 0 : '10px'}
          />
        ))}
        <Stack.Item>
          <Box>
            <Button
              color="transparent"
              icon="plus"
              content="Add Highlight Setting"
              onClick={() => {
                dispatch(addHighlightSetting());
              }}
            />
            {highlightSettings.length >= WARN_AFTER_HIGHLIGHT_AMT && (
              <Box inline fontSize="0.9em" ml={1} color="red">
                <Icon mr={1} name="triangle-exclamation" />
                Large amounts of highlights can potentially cause performance
                issues!
              </Box>
            )}
          </Box>
        </Stack.Item>
      </Stack>
      <Divider />
      <Box>
        <Button icon="check" onClick={() => dispatch(rebuildChat())}>
          Apply now
        </Button>
        <Box inline fontSize="0.9em" ml={1} color="label">
          Can freeze the chat for a while.
        </Box>
      </Box>
    </Section>
  );
};

const TextHighlightSetting = (props, context) => {
  const { id, ...rest } = props;
  const highlightSettingById = useSelector(context, selectHighlightSettingById);
  const dispatch = useDispatch(context);
  const {
    enabled,
    highlightColor,
    highlightText,
    highlightWholeMessage,
    matchWord,
    matchCase,
  } = highlightSettingById[id];
  return (
    <Stack.Item {...rest}>
      <Stack mb={1} color="label" align="baseline">
        <Stack.Item grow>
          <Button.Checkbox
            checked={!!enabled}
            content="Enabled"
            mr="5px"
            onClick={() =>
              dispatch(
                updateHighlightSetting({
                  id: id,
                  enabled: !enabled,
                }),
              )
            }
          />
          <Button
            content="Delete"
            color="transparent"
            icon="times"
            onClick={() =>
              dispatch(
                removeHighlightSetting({
                  id: id,
                }),
              )
            }
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={highlightWholeMessage}
            content="Whole Message"
            tooltip="If this option is selected, the entire message will be highlighted in yellow."
            mr="5px"
            onClick={() =>
              dispatch(
                updateHighlightSetting({
                  id: id,
                  highlightWholeMessage: !highlightWholeMessage,
                }),
              )
            }
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            content="Exact"
            checked={matchWord}
            tooltipPosition="bottom-start"
            tooltip="If this option is selected, only exact matches (no extra letters before or after) will trigger. Not compatible with punctuation. Overriden if regex is used."
            onClick={() =>
              dispatch(
                updateHighlightSetting({
                  id: id,
                  matchWord: !matchWord,
                }),
              )
            }
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            content="Case"
            tooltip="If this option is selected, the highlight will be case-sensitive."
            checked={matchCase}
            onClick={() =>
              dispatch(
                updateHighlightSetting({
                  id: id,
                  matchCase: !matchCase,
                }),
              )
            }
          />
        </Stack.Item>
        <Stack.Item>
          <ColorBox mr={1} color={highlightColor} />
          <Input
            width="5em"
            monospace
            placeholder="#ffffff"
            value={highlightColor}
            onInput={(e, value) =>
              dispatch(
                updateHighlightSetting({
                  id: id,
                  highlightColor: value,
                }),
              )
            }
          />
        </Stack.Item>
      </Stack>
      <TextArea
        height="3em"
        resize="vertical"
        value={highlightText}
        placeholder="Put words to highlight here. Separate terms with commas, i.e. (term1, term2, term3)"
        onChange={(e, value) =>
          dispatch(
            updateHighlightSetting({
              id: id,
              highlightText: value,
            }),
          )
        }
      />
    </Stack.Item>
  );
};

const ExperimentalSettings = (props, context) => {
  const { websocketEnabled, websocketServer } = useSelector(
    context,
    selectSettings,
  );
  const dispatch = useDispatch(context);

  return (
    <Section>
      <Stack vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Websocket Client">
              <Button.Checkbox
                content={'Enabled'}
                checked={websocketEnabled}
                color="transparent"
                onClick={() =>
                  dispatch(
                    updateSettings({
                      websocketEnabled: !websocketEnabled,
                    }),
                  )
                }
              />
              <Button
                icon={'question'}
                onClick={() => {
                  chatRenderer.processBatch([
                    {
                      html:
                        '<div class="boxed_message"><b>Websocket Information</b><br><span class="notice">' +
                        'Quick rundown. This connects to the specified websocket server, and ' +
                        'forwards all data/payloads from the server, to the websocket. Allowing ' +
                        'you to have in-game actions reflect in other services, or the real ' +
                        'world, (ex. Reactive RGB, haptics, play effects/animations in vtubing ' +
                        'software, etc). You can find more information ' +
                        '<a href="https://github.com/Monkestation/Monkestation2.0/pull/5744">here in the pull request.</a></span></div>',
                    },
                  ]);
                }}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Websocket Server">
              <Stack.Item>
                <Stack>
                  <Input
                    width={'100%'}
                    value={websocketServer}
                    placeholder="localhost:1990"
                    onChange={(e, value) =>
                      dispatch(
                        updateSettings({
                          websocketServer: value,
                        }),
                      )
                    }
                  />
                </Stack>
              </Stack.Item>
            </LabeledList.Item>
            <LabeledList.Item label="Websocket Controls">
              <Button
                ml={0.5}
                content="Force Reconnect"
                icon={'globe'}
                color={'good'}
                onClick={() => {
                  dispatch(reconnectWebsocket({}));
                }}
              />
              <Button
                ml={0.5}
                content="Force Disconnect"
                icon={'globe'}
                color={'bad'}
                onClick={() => {
                  dispatch(disconnectWebsocket({}));
                }}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const TabsViews = ['default', 'classic', 'scrollable'];
const LinkedToChat = () => (
  <NoticeBox color="red">Unlink Stat Panel from chat!</NoticeBox>
);

const SettingsStatPanel = (props, context) => {
  const { statLinked, statFontSize, statTabsStyle } = useSelector(
    context,
    selectSettings,
  );
  const dispatch = useDispatch(context);

  return (
    <Section fill>
      <Stack fill vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Tabs" verticalAlign="middle">
              {TabsViews.map((view) => (
                <Button
                  key={view}
                  color="transparent"
                  selected={statTabsStyle === view}
                  onClick={() =>
                    dispatch(updateSettings({ statTabsStyle: view }))
                  }
                >
                  {capitalize(view)}
                </Button>
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Font size">
              <Stack.Item grow>
                {statLinked ? (
                  <LinkedToChat />
                ) : (
                  <Slider
                    width="100%"
                    step={1}
                    stepPixelSize={20}
                    minValue={8}
                    maxValue={32}
                    value={statFontSize}
                    unit="px"
                    format={(value) => toFixed(value)}
                    onChange={(e, value) =>
                      dispatch(updateSettings({ statFontSize: value }))
                    }
                  />
                )}
              </Stack.Item>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Divider mt={2.5} />
        <Stack.Item textAlign="center">
          <Button
            fluid
            icon={statLinked ? 'unlink' : 'link'}
            color={statLinked ? 'bad' : 'good'}
            onClick={() =>
              dispatch(updateSettings({ statLinked: !statLinked }))
            }
          >
            {statLinked ? 'Unlink from chat' : 'Link to chat'}
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
