const path = require("path");
const webpack = require("webpack");
const { merge } = require('webpack-merge');
//const ClosurePlugin = require('closure-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const MinifyBundledPlugin = require('minify-bundled-webpack-plugin');
const MergeIntoSingleFilePlugin = require('webpack-merge-and-include-globally');

bundleVendorLibs = new MergeIntoSingleFilePlugin({
  files: {
    "./js/vendor.bundle.js": [
      //path.resolve(__dirname, 'node_modules/bootstrap/dist/js/bootstrap.bundle.min.js')
    ]
  }
});

var common = {
  entry: {
    './js/main.js': ['./js/main.js'], // .concat(glob.sync('./vendor/**/*.js')),
    './css/modular.css': ['./less/index.less']
  },
  output: {
    filename: '[name]',
    path: path.resolve(__dirname, './public/dist'),
  },
  resolve: {
    extensions: ['.js', '.less', '.css'],
    modules: ['node_modules'],
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules)|(vendor)|(elm\.compiled)/,
        use: {
          loader: 'babel-loader'
        }
      }
    ]
  }
};

module.exports = (env, options) => {
  if (options.mode === "production") {
    return merge(common, {
      output: {
        chunkFilename: `[name].min.js`,
      },
      optimization: {
        minimize: true,
        splitChunks: {
          chunks: 'all',
        },
        //concatenateModules: false, // required by Closure compiler AGGRESSIVE_BUNDLE
        minimizer: [
          /*new ClosurePlugin({ 
            mode: 'AGGRESSIVE_BUNDLE',
          }, {
            // compiler flags here
            // compilation_level: 'ADVANCED',
            // jscomp_off: 'lintChecks'
            //
            // for debugging help, try these:
            // dependency_mode: 'NONE'
            //
            //formatting: 'PRETTY_PRINT',
            //debug: true,
            //renaming: false
          }),*/
          new TerserPlugin(), //  I can't fix ClosurePlugin for web3 libraries
          new OptimizeCSSAssetsPlugin({
            assetNameRegExp: /app\.css$/g
          }),
        ]
      },
      module: {
        rules: [
          /*{
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: [{
              loader: "elm-webpack-loader",
              options: {
                cwd: path.resolve(__dirname, "src"),
                optimize: true
              }
            }]
          },*/
          {
            test: /\.less$/,
            use: [MiniCssExtractPlugin.loader, 'css-loader?url=false', 'less-loader']
          }
        ]
      },
      plugins: [
        new MiniCssExtractPlugin({ filename: './css/app.css' }),
        //bundleVendorLibs,
        new CopyWebpackPlugin({patterns: [{ from: 'js/elm.compiled.js', to: 'js/elm.compiled.js' }]}),
        /*new MinifyBundledPlugin({
          // Specify the files to minifiy after they're copied
          patterns: ['public/dist/js/elm.compiled.js'],
        }),*/
        new webpack.optimize.LimitChunkCountPlugin({
          maxChunks: 1
        }),
      ],
      // Detailed preset without warnings, because of ClosurePlugin spam
      stats: {
        entrypoints: true,
        chunks: true,
        chunkModules: false,
        chunkOrigins: true,
        depth: true,
        usedExports: true,
        providedExports: true,
        optimizationBailout: true,
        errorDetails: true,
        publicPath: true,
        exclude: false,
        maxModules: Infinity,
        warnings: false
      }
    });
  } 
  else {
    return merge(common, {
      watch: true,
      optimization: {
        // Suggested for hot-loading
        namedModules: true,
        // Prevents compilation errors causing the hot loader to lose state
        noEmitOnErrors: true,
      },
      module: {
        rules: [
          /*{
              test: /\.elm$/,
              exclude: [/elm-stuff/, /node_modules/],
              use: [{
                loader: 'elm-webpack-loader',
                options: {
                  cwd: path.resolve(__dirname, "elm"),
                  verbose: true,
                  forceWatch: true
                }
              }]
          },*/
          {
            test: /\.less$/,
            use: [MiniCssExtractPlugin.loader, 'css-loader?url=false', 'less-loader']
          }
        ]
      },
      plugins: [
        // Put clear app.css of JS junk
        new MiniCssExtractPlugin({ filename: './css/app.css' }),
        // bundleVendorLibs,
        // Copy all static assets
        //new CopyWebpackPlugin([{ from: 'public/', to: './' }])
        new webpack.optimize.LimitChunkCountPlugin({
          maxChunks: 1
        }),
      ]
    });
  }
};
