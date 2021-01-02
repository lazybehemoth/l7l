# Le7el SPA
> More documentation at https://elm-spa.dev

## Local development

You can get this site up and running with those two commands:

```
npm run dev
npm run dev:webpack
```

### Other commands to know

There are a handful of commands in the [package.json](./package.json).

## Deploying

After you run `npm run build`, the contents of the `public` folder can be hosted as a static site. If you haven't hosted a static site before, I'd recommend using [IPFS](https://ipfs.io).

### Using IPFS

Install [ipfs-deploy](https://github.com/ipfs-shipyard/ipfs-deploy), then build and deploy:
 
__Build command:__ `npm run build`

__Publish directory:__ `ipfs-deploy public/`
