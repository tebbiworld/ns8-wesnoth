*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Variables ***
${CONFIG}    {"game_port":15000,"admin_password":"Admin#Pass 1","admin_password_clear":false,"motd":"CI server","connections_allowed":5,"versions_accepted":"","save_replays":false,"disallow_names":[],"log_level":"info"}

*** Test Cases ***
Install the module
    IF    '${SCENARIO}' == 'update'
        ${output}  ${rc} =    Execute Command    add-module ${UPDATE_FROM} 1    return_rc=True
    ELSE
        ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1    return_rc=True
    END
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Configure the module
    Run task    module/${module_id}/configure-module    ${CONFIG}    decode_json=${FALSE}

The game server is online
    Wait Until Keyword Succeeds    30 times    10 seconds    Server is online    ${module_id}

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    30 times    10 seconds    Server is online    ${module_id}

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['motd']}    CI server
    Should Be True    ${cfg['admin_password_set']}
    # the admin password must still be in the generated server configuration
    ${n} =    Run on node    runagent -m ${module_id} bash -c 'grep -c "Admin#Pass 1" "$AGENT_STATE_DIR/wesnothd.cfg"'
    Should Be Equal As Integers    ${n.strip()}    1

Secrets are stored in passwords.env only
    Secrets are kept out of the module environment    ${module_id}

*** Keywords ***
Server is online
    [Arguments]    ${mid}
    ${cfg} =    Run task    module/${mid}/get-configuration    {}
    Should Be True    ${cfg['server_running']}
    Should Be True    ${cfg['server_online']}
