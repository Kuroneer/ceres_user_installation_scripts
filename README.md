# Non-root ceres installation scripts

These scripts install both [configuradorfnmt](https://www.sede.fnmt.gob.es/descargas/descarga-software/instalacion-software-generacion-de-claves) and [autofirma](https://firmaelectronica.gob.es/Home/Descargas.html) in your linux home, without root access.

If you have a look at the scripts you'll see that they are only the `postinst`
deb scripts adapted to handle only paths in the `$HOME` dir.

The scripts accept a single parameter in case you want to override the default
installation path (`$HOME/opt`) and you may want to link to the differnt
launchers from your `bin` in order to have them in your `$PATH`.
