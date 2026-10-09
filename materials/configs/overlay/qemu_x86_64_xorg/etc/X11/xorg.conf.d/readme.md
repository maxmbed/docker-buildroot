# Calculer Xorg Modeline

Calculer  VESA CVT mode line à partir d'une résolution donné :

```sh
cvt 320 960 60
```

Puis copier le résultat dans 10-monitor.conf

```sh
Modeline "320x960_60.00"   24.75  320 336 368 416  960 963 973 996 -hsync +vsync
```
