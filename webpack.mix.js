const mix = require('laravel-mix');


/*
 |--------------------------------------------------------------------------
 | Mix Asset Management
 |--------------------------------------------------------------------------
 |
 | Mix provides a clean, fluent API for defining some Webpack build steps
 | for your Laravel application. By default, we are compiling the Sass
 | file for the application as well as bundling up all the JS files.
 |
 */

const MomentLocalesPlugin = require('moment-locales-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');

/** Deprecaciones de Dart Sass en Bootstrap 4 y SCSS antiguo (evita miles de líneas en consola). */
const SASS_SILENCED_DEPRECATIONS = [
    'slash-div',
    'import',
    'global-builtin',
    'color-functions',
    'legacy-js-api',
    'if-function',
    'color-4-api',
];

function applyQuietSassToWebpackRules(rules) {
    if (!rules) {
        return;
    }
    for (const rule of rules) {
        if (!rule) {
            continue;
        }
        if (rule.oneOf) {
            applyQuietSassToWebpackRules(rule.oneOf);
        }
        if (rule.rules) {
            applyQuietSassToWebpackRules(rule.rules);
        }
        const uses = rule.use;
        if (!uses || typeof uses === 'function') {
            continue;
        }
        const list = Array.isArray(uses) ? uses : [uses];
        for (const u of list) {
            if (!u || typeof u !== 'object') {
                continue;
            }
            const path = u.loader && String(u.loader);
            if (path && path.includes('sass-loader')) {
                u.options = u.options || {};
                const prev = u.options.sassOptions || {};
                const merged = [...(prev.silenceDeprecations || []), ...SASS_SILENCED_DEPRECATIONS];
                u.options.sassOptions = {
                    ...prev,
                    quietDeps: true,
                    silenceDeprecations: [...new Set(merged)],
                };
            }
        }
    }
}

mix.js('resources/src/main.js', 'public').js('resources/src/login.js', 'public')
    .vue();

mix.webpackConfig({
    output: {
        filename: 'js/[name].min.js',
        chunkFilename: 'js/bundle/[name].[hash].js',
    },
    plugins: [
        new MomentLocalesPlugin(),
        new CleanWebpackPlugin({
            cleanOnceBeforeBuildPatterns: ['./js/*'],
        }),
    ],
});

mix.webpackConfig((webpack, config) => {
    applyQuietSassToWebpackRules(config.module && config.module.rules);
    return {};
});