<!--
  Copyright (C) 2026 tebbi
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title"><h2>{{ $t("settings.title") }}</h2></cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification kind="error" :title="$t('action.get-configuration')" :description="error.getConfiguration" :showCloseButton="false" />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <!-- Live state -->
          <NsInlineNotification
            v-if="!loading.getConfiguration"
            :kind="server_online ? 'success' : (server_running ? 'warning' : 'info')"
            :title="serverStatusTitle"
            :description="$t('settings.connect_desc', { address })"
            :showCloseButton="false"
            class="info-tile"
          />
          <cv-form @submit.prevent="configureModule">
            <!-- Server -->
            <h4 class="section">{{ $t("settings.server_section") }}</h4>
            <cv-number-input :label="$t('settings.game_port')" v-model="game_port" :min="1024" :max="65535" :helper-text="$t('settings.game_port_helper')" :disabled="busy" :invalid-message="$t(error.game_port)" ref="game_port" class="field"></cv-number-input>
            <cv-text-input type="password" :label="$t('settings.admin_password')" v-model.trim="admin_password" :placeholder="admin_password_set ? $t('settings.admin_password_placeholder') : ''" :helper-text="$t('settings.admin_password_helper')" :password-hide-label="$t('settings.hide')" :password-show-label="$t('settings.show')" :disabled="busy || admin_password_clear" :invalid-message="$t(error.admin_password)" ref="admin_password" class="field"></cv-text-input>
            <div class="bx--form__helper-text">{{ admin_password_set ? $t("settings.admin_set") : $t("settings.admin_not_set") }}</div>
            <cv-toggle v-if="admin_password_set" value="adminClear" :label="$t('settings.admin_password_clear')" v-model="admin_password_clear" :disabled="busy" class="toggle">
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <cv-text-input :label="$t('settings.motd')" v-model.trim="motd" :placeholder="$t('settings.motd_placeholder')" :helper-text="$t('settings.motd_helper')" :disabled="busy" :invalid-message="$t(error.motd)" ref="motd" class="field"></cv-text-input>
            <cv-number-input :label="$t('settings.connections_allowed')" v-model="connections_allowed" :min="0" :max="1000" :helper-text="$t('settings.connections_allowed_helper')" :disabled="busy" class="field"></cv-number-input>
            <cv-text-input :label="$t('settings.versions_accepted')" v-model.trim="versions_accepted" :placeholder="$t('settings.versions_accepted_placeholder')" :helper-text="$t('settings.versions_accepted_helper')" :disabled="busy" :invalid-message="$t(error.versions_accepted)" ref="versions_accepted" class="field"></cv-text-input>
            <cv-toggle value="saveReplays" :label="$t('settings.save_replays')" v-model="save_replays" :disabled="busy" class="toggle">
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <div class="bx--form__helper-text">{{ $t("settings.save_replays_helper") }}</div>

            <!-- Moderation -->
            <h4 class="section">{{ $t("settings.moderation_section") }}</h4>
            <cv-text-area :label="$t('settings.disallow_names')" v-model="disallow_names_text" :placeholder="$t('settings.disallow_names_placeholder')" :helper-text="$t('settings.disallow_names_helper')" :disabled="busy" :invalid-message="$t(error.disallow_names)" ref="disallow_names" rows="3" class="field"></cv-text-area>
            <cv-dropdown :label="$t('settings.log_level')" v-model="log_level" :helper-text="$t('settings.log_level_helper')" :disabled="busy" class="field">
              <cv-dropdown-item value="warning">{{ $t("settings.log_warning") }}</cv-dropdown-item>
              <cv-dropdown-item value="info">{{ $t("settings.log_info") }}</cv-dropdown-item>
              <cv-dropdown-item value="debug">{{ $t("settings.log_debug") }}</cv-dropdown-item>
            </cv-dropdown>

            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification kind="error" :title="$t('action.configure-module')" :description="error.configureModule" :showCloseButton="false" />
              </cv-column>
            </cv-row>
            <NsButton kind="primary" :icon="Save20" :loading="loading.configureModule" :disabled="busy">{{ $t("settings.save") }}</NsButton>
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <!-- Server console -->
    <cv-row>
      <cv-column>
        <cv-tile light>
          <h4 class="section-first">{{ $t("settings.command_section") }}</h4>
          <cv-form @submit.prevent="runCommand">
            <cv-text-input :label="$t('settings.command')" v-model.trim="command" :placeholder="$t('settings.command_placeholder')" :helper-text="$t('settings.command_helper')" :disabled="loading.runCommand || !server_online" class="field"></cv-text-input>
            <NsButton kind="secondary" :icon="Send20" :loading="loading.runCommand" :disabled="loading.runCommand || !server_online || !command">{{ $t("settings.run_command") }}</NsButton>
          </cv-form>
          <NsInlineNotification v-if="error.runCommand" kind="error" :title="$t('action.run-command')" :description="error.runCommand" :showCloseButton="false" class="info-tile" />
          <div v-if="command_output !== null" class="field">
            <div class="bx--label">{{ $t("settings.command_output") }}</div>
            <pre class="console">{{ command_output || $t("settings.command_no_output") }}</pre>
          </div>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import { QueryParamService, UtilService, TaskService, IconService, PageTitleService } from "@nethserver/ns8-ui-lib";
import Send20 from "@carbon/icons-vue/es/send/20";

const NAME_RE = /^[^"\s,]+$/;
const VERSION_RE = /^[0-9A-Za-z_.*?+-]+$/;

export default {
  name: "Settings",
  mixins: [TaskService, IconService, UtilService, QueryParamService, PageTitleService],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: { page: "settings" },
      urlCheckInterval: null,
      Send20,
      game_port: 15000,
      admin_password: "",
      admin_password_set: false,
      admin_password_clear: false,
      motd: "",
      connections_allowed: 5,
      versions_accepted: "",
      save_replays: false,
      disallow_names_text: "",
      log_level: "info",
      server_running: false,
      server_online: false,
      server_version: "",
      players_online: null,
      node_ip: "",
      command: "",
      command_output: null,
      loading: { getConfiguration: false, configureModule: false, runCommand: false },
      error: {
        getConfiguration: "", configureModule: "", runCommand: "",
        game_port: "", admin_password: "", motd: "", versions_accepted: "", disallow_names: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    busy() {
      return this.loading.getConfiguration || this.loading.configureModule;
    },
    disallow_names() {
      return this.disallow_names_text.split(/[\r\n,]+/).map((p) => p.trim()).filter((p) => p.length > 0);
    },
    address() {
      return `${this.node_ip || "<node>"}:${this.game_port}`;
    },
    serverStatusTitle() {
      if (!this.server_running) return this.$t("settings.status_stopped");
      if (!this.server_online) return this.$t("settings.status_starting");
      if (this.players_online === null) return this.$t("settings.status_online_short", { version: this.server_version });
      return this.$t("settings.status_online", { version: this.server_version, players: this.players_online });
    },
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.getConfigurationAborted);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.getConfigurationCompleted);
      const res = await to(this.createModuleTaskForApp(this.instanceName, { action: taskAction, extra: { title: this.$t("action." + taskAction), isNotificationHidden: true, eventId } }));
      const err = res[0];
      if (err) {
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const c = taskResult.output;
      this.game_port = c.game_port || 15000;
      this.admin_password = "";
      this.admin_password_set = !!c.admin_password_set;
      this.admin_password_clear = false;
      this.motd = c.motd || "";
      this.connections_allowed = c.connections_allowed === undefined ? 5 : c.connections_allowed;
      this.versions_accepted = c.versions_accepted || "";
      this.save_replays = !!c.save_replays;
      this.disallow_names_text = (c.disallow_names || []).join("\n");
      this.log_level = c.log_level || "info";
      this.server_running = !!c.server_running;
      this.server_online = !!c.server_online;
      this.server_version = c.server_version || "";
      this.players_online = c.players_online === undefined ? null : c.players_online;
      this.node_ip = c.node_ip || "";
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let ok = true;
      const fail = (field, msg) => {
        this.error[field] = msg;
        if (ok && this.$refs[field]) this.focusElement(field);
        ok = false;
      };
      if (/["\n]/.test(this.admin_password)) fail("admin_password", "settings.invalid_characters");
      if (/\n/.test(this.motd)) fail("motd", "settings.invalid_characters");
      const versions = this.versions_accepted.split(",").map((v) => v.trim()).filter((v) => v);
      if (versions.some((v) => !VERSION_RE.test(v))) fail("versions_accepted", "settings.invalid_version_pattern");
      if (this.disallow_names.some((n) => !NAME_RE.test(n))) fail("disallow_names", "settings.invalid_name_pattern");
      return ok;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusSet = false;
      for (const e of validationErrors) {
        if (e.field !== "(root)") {
          const detail = e.value && typeof e.value === "string" ? ` (${e.value})` : "";
          this.error[e.field] = this.$t("settings." + e.error) + detail;
          if (!focusSet && this.$refs[e.field]) {
            this.focusElement(e.field);
            focusSet = true;
          }
        }
      }
    },
    async configureModule() {
      if (!this.validateConfigureModule()) return;
      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.configureModuleAborted);
      this.core.$root.$once(`${taskAction}-validation-failed-${eventId}`, this.configureModuleValidationFailed);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.configureModuleCompleted);
      const data = {
        game_port: Number(this.game_port),
        admin_password: this.admin_password,
        admin_password_clear: this.admin_password_clear,
        motd: this.motd,
        connections_allowed: Number(this.connections_allowed),
        versions_accepted: this.versions_accepted,
        save_replays: this.save_replays,
        disallow_names: this.disallow_names,
        log_level: this.log_level,
      };
      const res = await to(this.createModuleTaskForApp(this.instanceName, {
        action: taskAction,
        data,
        extra: { title: this.$t("settings.configure_instance", { instance: this.instanceName }), description: this.$t("common.processing"), eventId },
      }));
      const err = res[0];
      if (err) {
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;
      this.getConfiguration();
    },
    async runCommand() {
      if (!this.command) return;
      this.loading.runCommand = true;
      this.error.runCommand = "";
      this.command_output = null;
      const taskAction = "run-command";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.runCommandAborted);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.runCommandCompleted);
      const res = await to(this.createModuleTaskForApp(this.instanceName, {
        action: taskAction,
        data: { command: this.command },
        extra: { title: this.$t("action." + taskAction), isNotificationHidden: true, eventId },
      }));
      const err = res[0];
      if (err) {
        this.error.runCommand = this.getErrorMessage(err);
        this.loading.runCommand = false;
      }
    },
    runCommandAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.runCommand = this.$t("error.generic_error");
      this.loading.runCommand = false;
    },
    runCommandCompleted(taskContext, taskResult) {
      this.loading.runCommand = false;
      this.command_output = (taskResult.output && taskResult.output.output) || "";
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.field { margin-top: $spacing-06; }
.toggle { margin-top: $spacing-06; }
.info-tile { margin-top: $spacing-06; }
.section { margin-top: $spacing-07; margin-bottom: $spacing-03; }
.section-first { margin-bottom: $spacing-03; }
.console { font-family: monospace; white-space: pre-wrap; background: #f4f4f4; padding: $spacing-05; margin-top: $spacing-03; }
</style>
