import Vue from 'vue';
import VueLocalStorage from 'vue-localstorage';
import Languages from '../../translations';

Vue.use(VueLocalStorage);
const supportedLanguages = Object.getOwnPropertyNames(Languages);

const LANG_KEY = 'language';
/** Una sola vez: idioma vacío, inglés antiguo por defecto → español */
const DEFAULT_ES_FLAG = 'stocky_default_es_v1';

if (!Vue.localStorage.get(DEFAULT_ES_FLAG)) {
  const cur = Vue.localStorage.get(LANG_KEY);
  if (cur == null || cur === '' || cur === 'en') {
    Vue.localStorage.set(LANG_KEY, 'es');
  }
  Vue.localStorage.set(DEFAULT_ES_FLAG, '1');
}

export default {
  namespaced: true,
  state: {
    language: Vue.localStorage.get(LANG_KEY) || 'es',
  },
  mutations: {
    SET_LANGUAGE(state, lang) {
      Vue.localStorage.set(LANG_KEY, lang);
      state.language = lang;
    },
  },
  actions: {
    setLanguage({ commit }, languages) {
      if (typeof languages === 'string') {
        commit('SET_LANGUAGE', languages);
      } else {
        const language = supportedLanguages.find(sl =>
          languages.find(l => (l.split(new RegExp(sl, 'gi')).length - 1 > 0 ? sl : null)));
          commit('SET_LANGUAGE', language);
      }
    },
  },
};