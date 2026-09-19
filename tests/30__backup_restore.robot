*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Remove the original instance
    # the game port is published on the node: one server per port
    Run on node    remove-module --no-preserve ${module_id}

Restore into a new instance
    ${rid} =    Restore the module from the cluster repository    ${BACKUP_REPO}    ${BACKUP_PATH}
    Set Global Variable    ${restored_id}    ${rid}
    Set Global Variable    ${module_id}    ${rid}

The restored instance has settings and secrets
    ${cfg} =    Run task    module/${restored_id}/get-configuration    {}
    Should Be Equal    ${cfg['motd']}    CI server
    Should Be True    ${cfg['admin_password_set']}
    ${n} =    Run on node    runagent -m ${restored_id} bash -c 'grep -c "Admin#Pass 1" "$AGENT_STATE_DIR/wesnothd.cfg"'
    Should Be Equal As Integers    ${n.strip()}    1
    Secrets are kept out of the module environment    ${restored_id}
