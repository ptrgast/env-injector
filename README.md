# The problem
At some time when you create Vue single page applications you are going to need a way to configure your application dynamically. For this, Vue supports environment variables through `.env` files. As web applications run on the client side, environment variables can only be included in the application at the build time.

When deploying your applications with Docker containers, build time configurations can be difficult to manage as you are going to need an environment for building the application for every configuration change. This is at least time consuming and some times frustrating.

# Solutions
The core idea is to inject somehow the configuration variables in the application when the container starts. Some approaches out there suggest to have separate files excluded from bundles and minification, some other approaches suggest creating a side API that serves the configuration and some other suggest replacing a placeholder with a JavaScript object that holds the configuration.

# This script
This script belongs to the placeholder category. It uses customizable opening and closing tags used for  identifying the place of the injection and customizable object name for the injected variables.

# Usage

## Input document
The document that the variables will be injected is called "input document".

Use `-i="..."` to set the input document. 

## Tags
As already mentioned this script uses two tags; one opening tag called "the beginning tag" and a closing tag called "the ending tag" that are used to identify the place that the variables will be injected. 
The injection script preserves these tags in order to be able to replace any previous values at subsequent executions. These tags are customizable and can be set freely as long they don't break the containing document.

Use `-b="..."` for setting the beginning tag.

Use `-e="..."` for setting the ending tag.

## Object Name
The name of the generated object that contains the required environment variables is by default the `window.env` but it can also be set at will.

Use `-n="..."` to set the generated object name.

## Environment Variables

The names of the required environment variables can be passed to the script as plain arguments without some kind of prefix. The generated object will contain the same variables and the values that was retrieved by the system at the time of the execution. (See the example below)

# Example
Let's assume we have set somehow two environment variables. (This could be done at a docker run command or at a docker-compose.yml file)
```
VUE_APP_VAR1="hello"
VUE_APP_VAR2="world"
```

Now we can inject the variables into `index.html`
```
perl env-injector.pl -i="index.html" -b="<script data-type=env>" -e="</script>" VUE_APP_VAR1 VUE_APP_VAR2
```

If we put the above command in an entrypoint shell script, before starting our web server then the `index.html` file will be updated every time we start the container.

The above example will generate the following object between the `<script data-type=env></script>` tags:

```
window.env = {
    VUE_APP_VAR1: "hello",
    VUE_APP_VAR2: "world"
}
```

# Why Perl?
Perl is already present in various Docker images such as debian, ubuntu, nginx and httpd that could potentially be used to serve a web based JavaScript application.
