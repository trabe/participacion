> Documentación de UDCDecide.

> Versión 1: Noviembre 2017

# UDC Decide

Fork de la aplicación [cónsul](https://github.com/consul/consul). Adaptada para su uso en la Universidade de A Coruña.

En este documento todos los comandos se asumen lanzados desde la raíz del proyecto descargado.

### > Información

El fork de la Universidade da Coruña está alojado en el CIXUG, en este repositorio: https://git.cixug.es/osl/participacion

En concreto las adaptaciones realizadas sobre cónsul se encuentran en la rama __udcdecide__, que se puede encontrar aquí: https://git.cixug.es/osl/participacion/tree/udcdecide

Para futuros desarrollos se puede:
  * Seguir trabajando con esa rama. Asumiremos esta forma en el resto de instrucciones de desarrollo y despliegue.
  * Hacer un "merge" a _master_ y cambiar la configuración de despliegue para que sea la rama que se ponga en producción. Para ello editaremos la sección `branch` en la sección `production` del fichero `config/deploy-secrets.yml`

## _ Instalación del sistema

Detallaremos los pasos necesarios para instalar el sistema en desarrollo.

Estas instrucciones asumen que se está utilizando un entorno Ubuntu Linux, en una versión actualizada (2017 al menos).

Las instrucciones son válidas para configurar un entorno de producción y uno de desarrollo. En caso de existir diferencias se aclaran en cada punto.

Es importante no pasar al siguiente paso antes de haber completado los anteriores.

### > Software necesario

#### git

Si no estuviese instalado en el sistema, basta con ejecutar:

```
$ sudo apt-get install git
```

Para seguir este manual y para desarrollo y despliegue del sistema es necesario tener conocimientros de trabajo con _git_. Se manejarán comandos como _push_, _pull_, _merge_ y trabajo con ramas (_branch_).

La [documentación oficial](https://git-scm.com/book/en/v2) es una buena fuente de aprendizaje en caso de no estar familiarizado con git.


#### ruby

* En producción instalarlo "standalone" ejecutando `$ sudo apt-get install ruby<version>` donde <version> es la versión que se indica en el fichero `.ruby-version` de la raiz del proyecto. Si no se encontrase, instalar una versión de ruby2 >= 2.1.

* En desarrollo es recomendable instalarlo usando el gestor de versiones de ruby [_rbenv_](https://github.com/rbenv/rbenv). Para ello, se instala primero rbenv y luego el ruby que se necesite (usa el fichero `.ruby-version` del que hablamos). Para ello

  1. Seguir los pasos indicados [aquí]( https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-16-04) hasta antes de "Install Ruby"
  * Correr `$ rbenv install`, que instará la versión configurada en `.ruby-version`


#### gem

Las gemas son los paquetes de software de ruby. Una vez instalado ruby lo que instalaremos a continuación serán gemas.

En principio sólo inistalaremos `bundler` usando el comando gem, luego este gestor nos abstraerá el uso del comando `gem`.

#### bundler

Bundlers es un gestor de dependencias ruby.

Nos permitirá instalarlas, configurar las que necesita nuestro software en un fichero `Gemfile` y ejecutarlas en un contexto cerrado. De no estar familiarizado con bundler, se recomienda la [documentación oficial](http://bundler.io/docs.html).

Para instalarlo sólo tenemos que ejecutar:

    $ gem install bundler

Los comandos que comienzan con rake y rails deberán ir precedidos de `bundle exec`.

#### posgresql

Si no estuviese instalado, podemos instalarlo ejecutando:

    $ sudo apt-get install postresql postresql-contrib

Esto creará un usuario y contraseña por defect, que se usará en la configuración de desarrollo.
En producción es muy aconsejable crear un usuario separado y configurarlo en la app (ver sección de instalación en servidor)

### > Repositorio

Para poder acceder al repositorio hay que contactar con el CIXUG, por ejemplo a través del adjunto de participación ([participacion.vepeu@udc.gal](mailto:participacion.vepeu@udc.gal)).

Además, tendrás como mínimo que configurar git y una clave ssh para poder conectarte al repositorio. Estos conceptos básicos están cubiertos en el [README](https://docs.gitlab.com/ce/gitlab-basics/README.html) de Gitlab así como en la documentación de Git ya comentada.

El repositorio se encuentra en https://git.cixug.es/osl/participacion y la rama que nos interesa es _udcdecide_

Una vez configurado git y configurada la clave en gitblab, para descargarlo y empezar a trabajar sobre la rama hacemos:

    $ git clone http://git.cixug.es/osl/participacion.git
    $ git checkout branch udcdecide

### > Instalación

Los pasos son iguales en desarrollo y en producción, indicándose en caso de que no sea así. Además, para opciones exclusivas de producción se añade una sección específica.

Para instalar el sistema, una vez instalado lo anterior y desde el directorio en el que nos hemos descargado el repositorio tenemos que:

#### Instalar las gemas necesarias

    $ bundle install

#### Crear una base de datos para la aplicación

Para ello podemos usar el comando de postgres [`createdb`](https://www.postgresql.org/docs/9.1/static/app-createdb.html).

    $ createdb <NOMBRE_DE_A_BD>

Si no lo estuviese, tenemos que [arrancar postgresql](https://www.postgresql.org/docs/9.1/static/server-start.html) previamente.

    $ postgres -D /usr/local/pgsql/data


#### Crear los ficheros de configuración

Estos son ficheros especiales que contienen credenciales que no deben guardarse en el repositorio o que deben configurarse por entorno. Están en formato [yaml](http://yaml.org).

Necesitaremos: `config/database.yml`,  `config/secrets.yml` y `config/deploy-secrets.yml`. Podemos comenzar con las plantilla que se proporcionan en config y que tienen el mismo nomnbre acabado en _.example_ o los ejemplos siguientes, donde se extrae sólo lo necesario.

Hay que tener en cuenta que deberemos cambiar las variables que se indican entre `<VARIABLE>`

**config/database.yml**

Usado por la aplicación para conectarse a la base de datos adecuada.

Se necesita una versión adaptada con en `<NOMBRE_DE_USUARIO>`, `<CONTRASEÑA>` y `<NOMBRE_DE_LA_BD>` tanto en desarrollo como en producción.

```
default: &default
  adapter: postgresql
  encoding: unicode
  host: localhost
  pool: 5
  username: <NOMBRE_DE_USUARIO>
  password: <CONTRASEÑA>

development: &development
  <<: *default
  database: <NOMBRE_DE_LA_BD>

production:
  <<: *development
```

**config/deploy-secrets.yml**

Usado por el comando de despliegue cap deploy (configurado en `config/deploy.rb`). Aquí se incluyen los datos actuales del servidor en el que está desplegada la app.

Este fichero sólo es requerido en desarrollo

```
production:
 deploy_to: "/home/participa"
 branch_to_deploy: udcdecide
 ssh_port: 22
 server: 10.8.16.195
 user: participa
 full_app_name: udcdecide.udc.gal
```

**config/secrets.yml**

Aquí se configura el token que se usa para verificar las cookies, además de algunas opciones de configuración, como la url del CAS.

En este caso <TOKEN_SECRETO> es el resultado de ejecutar `$ bundle exec rake secret` desde la raíz del proyecto, generaremos uno distinto para cada TOKEN idealmente.

```
default: &default
  secret_key_base: <TOKEN_SECRETO>

development:
  <<: *default

test:
  <<: *default

production: &production
  secret_key_base: <TOKEN_SECRETO>
  cas_server: 'cas.udc.es'
```

### Crear la base de datos

Para ello creamos la base de datos, corremos las migraciones

    bin/rake db:create
    bin/rake db:migrate

En desarrollo, metemos los datos iniciales de prueba de _dev_seed_

    bin/rake db:dev_seed

En producción hacemos lo mismo, pero

    bin/rake db:seed

Estos datos iniciales, semillas o _seeds_ se pueden configurar en `db/seeds.rb` y `db/dev-seeds.rb`.

### Correr la app (desarrollo)

Usaremos el comando de rails [`rails server`](http://guides.rubyonrails.org/command_line.html#rails-server), llamándolo así arrancaremos el servidor en el puerto 3000

```
$ bin/rails server
```

Si queremos ejecutarlo en un puerto concreto:

```
$ bin/rails server -p 4321
```

### > Instrucciones específicas para instalación en producción

#### Máquina de producción

> * Info de la máquina de producción, ip, etc

#### Configuración

> * Las cosas que cambian en producción
> * apache? -> David

### > Despliegue

Hay que estar en la red de la universidad, sinó no se podrá realizar el despliegue (o conectarse a producción).

El script `config/deploy.rb` automatiza todo el proceso, así que sólo tendremos que ejecutar esta tarea de [capistrano](http://capistranorb.com/):

      $ bundle exec cap deploy

Cuando acabe el comando, que puede tardar varios minutos, lo que tengamos en la rama `udcdecide` (o otra si así lo hemos configurado) estará correctamente desplegado en http://udcdecide.udc.gal (o otro si lo hemos cambiado).

---
<div class="page-break"></div>

# Manual para realizar cambios de datos en la plataforma

### _ Cambiar textos html


#### Máis información / Política de privacidade / etc.

Son ficheiros erb que generan html. Se encuentran en `app/views/pages/`, en concreto los dos que nos interesan son:

* `app/views/pages/more_information.html.erb` -> "Más información"
* `app/views/pages/privacy.html.erb` -> "Política de privacidade"
* `app/views/pages/proposals_info.html.erb` -> "Información sobre as propostas"

Aunque estos ficheiros pueden contener exclusivamente html también admiten cualquier tipo de notación en [`erb`](http://guides.rubyonrails.org/layouts_and_rendering.html).

Para enlazar a ellos desde cualquier otra página o plantilla erb podemos usar la función auxiliar `page_link`. Por ejemplo en el footer:

```
  <div class="small-12 large-3 column">
    <ul>
      <li><%= link_to t("layouts.footer.more_info"), page_path('more_information') %></li>
      <li><%= link_to t("layouts.footer.privacy"), page_path('privacy') %></li>
    </ul>
  </div>
```

Una vez realizados los cambios y guardado el fichero podemos ver el resultado, si tenemos el servidor de desarrollo corriendo en

* http://localhost:3000/privacy
* http://localhost:3000/more_information

Para que los cambios se hagan efectivos en producción habría además que hacer un commit con los cambios, hacer un push al repositorio y desplegar en producción. Por ejemplo, si cambiamos `more_information`:

```
  $ git add app/views/pages/more_information.html.erb
  $ git commit -m "Modificadas instruccións de 'Máis información'"
  $ git push
  $ bundle exec cap deploy
```

#### Pie de página

El _footer_ o pie de página se encuentra en `app/views/layouts/_footer.html.erb` y los pasos para modificarlo son los mismos que en el caso de las páginas de información.


### _ Nombres de los centros

Los "centros" son simplemente etiquetas especiales de clasificación de elementos del portal. Cuando se actualizó el primer portal participativo de la UDC a la última versión de Cónsul todavía era un elemento novedoso, por lo que no se dispone de una  herramienta de administración visual.

Para importar los centros "por defecto", extraídos del portal de la UDC hay una tarea rake que los crea o resetea a su estado original:

      $ rake db:udc_geozones_seed  # Resets geozones to the UDC ones from db/udc_geozone_seeds.rb

Si se quiere cambiar el nombre de un centro específico hay que actuar directamente sobre la base de datos. No se recomenda y **hay que tener mucho cuidado con no eliminoar ninguno existente** pues podríamos hacer que el portal no funcione.

La tabla en cuestión es ´geozones´. Podemos listar su contenido desde la consola de postgresql

consul_development=# select * from geozones;

```
 id |                               name                                | html_map_coordinates | external_code |         created_at         |         updated_at         | census_code
----+-------------------------------------------------------------------+----------------------+---------------+----------------------------+----------------------------+-------------
  2 | Escola Técnica Superior de Arquitectura                           |                      |               | 2017-10-16 11:10:11.693148 | 2017-10-16 11:10:11.693148 |
  3 | Escola Técnica Superior de Enxeñeiros de Camiños, Canais e Portos |                      |               | 2017-10-16 11:10:11.714192 | 2017-10-16 11:10:11.714192 |
  4 | Escola Técnica Superior de Náutica e Máquinas                     |                      |               | 2017-10-16 11:10:11.719314 | 2017-10-16 11:10:11.719314 |
  5 | Escola Universitaria de Arquitectura Técnica                      |                      |               | 2017-10-16 11:10:11.724947 | 2017-10-16 11:10:11.724947 |
  6 | Facultade de Ciencias                                             |                      |               | 2017-10-16 11:10:11.730613 | 2017-10-16 11:10:11.730613 |
  7 | Facultade de Ciencias da Comunicación                             |                      |               | 2017-10-16 11:10:11.736388 | 2017-10-16 11:10:11.736388 |
  8 | Facultade de Ciencias da Educación                                |                      |               | 2017-10-16 11:10:11.741547 | 2017-10-16 11:10:11.741547 |
  9 | Facultade de Ciencias da Saúde                                    |                      |               | 2017-10-16 11:10:11.746853 | 2017-10-16 11:10:11.746853 |
 10 | Facultade de Ciencias do Deporte e a Educación Física             |                      |               | 2017-10-16 11:10:11.753028 | 2017-10-16 11:10:11.753028 |
 11 | Facultade de Dereito                                              |                      |               | 2017-10-16 11:10:11.757071 | 2017-10-16 11:10:11.757071 |
 12 | Facultade de Economía e Empresa                                   |                      |               | 2017-10-16 11:10:11.769814 | 2017-10-16 11:10:11.769814 |
 13 | Facultade de Filoloxía                                            |                      |               | 2017-10-16 11:10:11.791209 | 2017-10-16 11:10:11.791209 |
 14 | Facultade de Fisioterapia                                         |                      |               | 2017-10-16 11:10:11.801547 | 2017-10-16 11:10:11.801547 |
 15 | Facultade de Informática                                          |                      |               | 2017-10-16 11:10:11.808021 | 2017-10-16 11:10:11.808021 |
 16 | Facultade de Socioloxía                                           |                      |               | 2017-10-16 11:10:11.835769 | 2017-10-16 11:10:11.835769 |
 17 | Escola Politécnica Superior                                       |                      |               | 2017-10-16 11:10:11.844379 | 2017-10-16 11:10:11.844379 |
 18 | Escola Universitaria de Deseño Industrial                         |                      |               | 2017-10-16 11:10:11.849576 | 2017-10-16 11:10:11.849576 |
 19 | Escola Universitaria Politécnica                                  |                      |               | 2017-10-16 11:10:11.857427 | 2017-10-16 11:10:11.857427 |
 20 | Facultade de Ciencias do Traballo                                 |                      |               | 2017-10-16 11:10:11.86264  | 2017-10-16 11:10:11.86264  |
 21 | Facultade de Enfermaría e Podoloxía                               |                      |               | 2017-10-16 11:10:11.87251  | 2017-10-16 11:10:11.87251  |
 22 | Facultade de Humanidades e Documentación                          |                      |               | 2017-10-16 11:10:11.879697 | 2017-10-16 11:10:11.879697 |
 23 | Escola Universitaria de Enfermaría                                |                      |               | 2017-10-16 11:10:11.889543 | 2017-10-16 11:10:11.889543 |
 24 | Escola Universitaria de Relacións Laborais                        |                      |               | 2017-10-16 11:10:11.907296 | 2017-10-16 11:10:11.907296 |
 25 | Escola Universitaria de Turismo                                   |                      |               | 2017-10-16 11:10:11.939197 | 2017-10-16 11:10:11.939197 |
(24 rows)
```

Y si queremos cambiar, por ejemplo el nombre de la Facultade de Informática:

    # update geozones set name = 'FIC' where id=15;

Se recomienda no eliminar niunguna, pero si se comprueba que no hay ningún elemento relacionado con la misma (en principio sólo debates, usuarios y propuestas podrían estarlo).

    # delete from geozones where id=15;

De ser una operación habitual se aconseja solicitar una herramienta para hacer estas operaciones más seguras y cómodas. Ya sea en forma de herramienta de línea de comandos o una opción en administración.


### _ Otros cambios

#### Borrar Usuarios / Bloquear usuarios

Los usuarios pueden borrar su cuenta desde su menú de usuario. Pulsando en la parte superior de la pantalla "A miña conta" y luego en "Darme de baixa".

Un **administrador** también podrá borrar usuarios que han sido bloqueados. Para ello podrá acceder a la sección de [usuarios bloqueados](http://udc-participa.dev/admin/users) donde se listan los usuarios que han sido bloqueados. Ahí verá un botón para eliminarlo en los botones de acción. Además podrá confirmas su bloqueo (simplemente lo quita de la cola de revisión) o cancelar el bloqueo.

Si se quiere eliminar un usuario del que no se ha solicitado bloqueo previamente hay que bloquearlo en esa sección de moderación > [bloquear usuarios](http://udc-participa.dev/moderation/users).

Téngase en cuenta que:
* En cuanto se bloquea un usuario desde moderación el usuario no podrá volver a acceder a la web, y todas sus Propuestas/Debates/Comentarios serán ocultados y dejarán de ser visibles en la web.

* La confirmación del bloqueo por parte del administrador simplemente lo quita de la cola de revisión. Además ahí dispone de otras acciones, como cancelar el bloqueo o eliminar el usuario.

* Cuando se elimina un usuario se borra la información del usuario y sus identidades, por lo que el usuario podría volver a registrarse con el CAS.

* Si un usuario se bloquea no podría volver a regirstarse con la misma identidad.

#### Otros textos

La mayoría de los textos de la aplicación están extraidos para facilitar su internacionalización.

Cuando en un fichero erb se encuentre el heper `t`, por ejemplo <%= t "admin.users.name" %> significa que en `config/locales` hay un fichero [yaml](https://learnxinyminutes.com/docs/yaml/) que tiene esa cadena de texto.

Una buena opción para enccontrar donde está definido es buscar por una de las cadenas, si queremos saber dónde se encuentra la cadenadel texto anterior, por ejemplo, podemos buscar "admin:". La cadena en concreto se encontrará anidada bajo `admin` en alguno de los ficheros como sigue:

```
gl:
  admin:
    users:
      name: "Nome"
```

Si no se sabe que cadena corresponde a un texto podemos optar por buscar la cadena. Una búsqueda de "Nome" en el directorio dará varios resultados, entre los que podemos encontrar el anterior.

#### Otros cambios

Otro tipo de cambios de funcionamiento en la plataforma requieren conocimientos de rails y del sistema cónsul más en detalle.

De existir interés en algún tema concreto pueden contactar con [nosotros](mailto:contact@trabe.io).
---
<div class="page-break"></div>

## _ Manual de administración

Desde esta sección (http://udcdecide.udc.gal/admin) puedes administrar el sistema, a través de las siguientes acciones:

### > Temas de debate

Los temas (también llamadas tags, o etiquetas) de debate son palabras que definen los usuarios al crear debates, para catalogarlos (ej: sanidad, movilidad, arganzuela, ...). Aquí se pueden eliminar temas inapropiados, o marcarlos para ser propuestos al crear debates (cada usuario puede definir los que quiera, pero se le sugieren algunos que nos parecen útiles como catalogación por defecto; aquí se puede cambiar cuáles se sugieren)

### > Propuestas/Debates/Comentarios ocultos

Cuando un moderador o un administrador oculta una Propuesta/Debate/Comentario aparecerá en esta lista. De esta forma los administradores pueden revisar que se ha ocultado el elemento adecuado.

Al pulsar Confirmar se acepta el que se haya ocultado, se considera que se ha hecho correctamente.

Al pulsar Volver a mostrar se revierte la acción de ocultar y vuelve a ser una Propuesta/Debate/Comentario visible, en el caso de que se considere que ha sido una acción errónea el haberlo ocultado.

Para facilitar la gestión, arriba encontramos un filtro con las secciones: "pendientes" (los elementos sobre los que todavía no se ha pulsado "confirmar" o "volver a mostrar", que deberían ser revisados todavía), "confirmados" y "todos".

Es recomendable revisar regularmente la sección "pendientes".

### > Usuarios bloqueados

Cuando un moderador o un administrador bloquea a un usuario aparecerá en esta lista. Al bloquear a un usuario, éste deja de poder utilizarlo para ninguna acción de la web. Los administradores pueden desbloquearlos pulsando el botón al lado del nombre del usuario en la lista.


### > Cargos Públicos

En la web, los usuarios individuales pueden ser usuarios normales, o cargos públicos. Estos últimos se diferencian de los primeros únicamente en que al lado de sus nombres aparece una etiqueta que les identifica, y cambia ligeramente el estilo de sus comentarios. Esto permite que los usuarios les identifiquen más fácilmente.

Al lado de cada usuario vemos la identificación que aparece en su etiqueta, y su nivel (la manera que
internamente usa la web para diferenciar entre un tipo de cargos y otros). Pulsando el botón "Editar" al lado del usuario, se puede modificar su información. Los cargos públicos que no aparecen en la lista pueden ser encontrados para actuar sobre ellos por medio del buscador en la parte superior.

### > Moderadores

Mediante el buscador de la parte superior se pueden buscar usuarios, para activarlos o desactivarlos como moderadores de la web. Los moderadores al acceder a la web con su usuario ven en la parte superior una nueva sección llamada "Moderar"

### >Actividad de moderadores

En esta sección se va guardando todas las acciones que realizan los moderadores o los administradores respecto a la moderación: ocultar/mostrar Propuestas/Debates/Comentarios y bloquear usuarios. En la columna "Acción" comprobamos si la acción corresponde con ocultar o con volver a mostrar (restaurar) elementos o con bloquear usuarios. En las demás columnas tenemos el tipo de elemento, el contenido del elemento y el moderador o administrador que ha realizado la acción. Esta sección permite que los administradores detecten comportamientos irregulares por parte de moderadores específicos y que por lo tanto puedan corregirlos.

### > Configuración Global
Opciones generales de configuración del sistema.

La mayoría de las opciones de configuración no se deben tocar. Algunas no cambiarán nada que se pueda ver en udc-decide, pero otras pueden hacer que el portal deje de funcionar. Es importante no activar funcionalidades que no son las activadas por defecto, ya que no se han configurado ni probado en el fork.

Aquí podemos cambiar sin problema:
* Los nombres de distintos niveles de cargos públicos
* "Porcentaje máximo de votos anónimos por debate"
* "Número de votos en que un Debate deixa de se poder editar"
* "Prefixo para os códigos de Propostas"
* "Número de votos necesarios para aprobar unha Proposta"
* "Código a incluir en cada páxina". Lo que pongamos aquí aparecerá en la parte superior de cada página del portal. Por ejemplo:
```
<div style="text-align: center; background-color: lightslategray;color: lightgray;font-size: 1.5em;">
    Mantemento da plataforma o Xoves ás 23.00 a web pode deixar de esatar operativa por un tempo.
</div>
```

### > Estadísticas
Aquí se muestran estadísticas generales del sistema sobre usuarios, propuestas, votos...

---
<div class="page-break"></div>

## _ Manual de moderación

### > Propuestas / Debates / Comentarios
Cuando un usuario marca en una Propuesta/Debate/Comentario la opción de "denunciar como inapropiado", aparecerá en esta lista. Respecto a cada uno aparecerá el título, fecha, número de denuncias (cuántos usuarios diferentes han marcado la opción de denuncia) y el texto de la Propuesta/Debate/Comentario.

A la derecha de cada elemento aparece una caja que podemos marcar para seleccionar todos los que queramos de la lista. Una vez seleccionados uno o varios, encontramos al final de la página tres botones para realizar acciones sobre ellos:

* **Ocultar:** hará que esos elementos dejen de mostrarse en la web.

* **Bloquear autores:** hará que el autor de ese elemento deje de poder acceder a la web, y que además todos las Propuestas/Debates/Comentarios de ese usuario dejen de mostrarse en la web.

* **Marcar como revisados:** cuando consideramos que esos elementos no deben ser moderados, que su contenido es correcto, y que por lo tanto deben dejar de ser mostrados en esta lista de elementos inapropiados.

Para facilitar la gestión, arriba encontramos un filtro con las secciones:

* **Pendientes:** las Propuestas/Debates/Comentarios sobre los que todavía no se ha pulsado "ocultar", "bloquear" o "marcar como revisados", y que por lo tanto deberían ser revisados todavía

* **Todos:** mostrando todos las Propuestas/Debates/Comentarios de la web, y no sólo los marcados como inapropiados.

* **Marcados como revisados:** los que algún moderador ha marcado como revisados y por lo tanto parecen correctos.

Es recomendable revisar regularmente la sección "pendientes".

### > Bloquear usuarios

Un buscador nos permite encontrar cualquier usuario introduciendo su nombre de usuario o correo electrónico, y bloquearlo una vez encontrado.

Al bloquearlo, el usuario no podrá volver a acceder a la web, y todas sus Propuestas/Debates/Comentarios serán ocultados y dejarán de ser visibles en la web.
