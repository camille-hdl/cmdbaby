"""Génère l'icône d'app (⌘ + biberon dans un squircle) et le picto de barre de menus."""
import math, pathlib

OUT = pathlib.Path(__file__).parent / "out"
OUT.mkdir(exist_ok=True)

# Palettes camillehdl.dev/palette et /palette-night
DAY = dict(paper="#fff1e5", raised="#fff9f2", s1="#f7e7d8", s2="#f2dfce", slate="#262a33",
           claret="#990f3d", claretB="#bf5f80", oxford="#0f5499", oxfordB="#1e6ec4",
           teal="#0d7680", mandarinB="#bf6626")
NIGHT = dict(paper="#1f1915", raised="#261f1a", s1="#2b231d", s2="#3a2f27", ink="#e3d1bf", wheat="#f2dfce",
             claret="#d28e9b", oxford="#7da5d2", oxfordB="#9ab6d6", mandarin="#d2905f", teal="#4db4ba")


def squircle(cx, cy, half, n=5.0, steps=720):
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s = math.cos(t), math.sin(t)
        x = half * math.copysign(abs(c) ** (2 / n), c)
        y = half * math.copysign(abs(s) ** (2 / n), s)
        pts.append(f"{cx + x:.2f},{cy + y:.2f}")
    return "M" + " L".join(pts) + " Z"


def command_path(a, r):
    """Symbole ⌘ centré en 0,0 : quatre traits qui se croisent et quatre boucles de 270°."""
    k = a + r
    return (f"M{-k},{-a} L{k},{-a} A{r},{r} 0 1 0 {a},{-k} "
            f"L{a},{k} A{r},{r} 0 1 0 {k},{a} "
            f"L{-k},{a} A{r},{r} 0 1 0 {-a},{k} "
            f"L{-a},{-k} A{r},{r} 0 1 0 {-k},{-a} Z")


def bottle(c, glass, milk, teat, collar, outline, bubble, stroke):
    """Biberon élancé : corps 0,78 × 1,30, pointe de la tétine en y≈0, fond en y=1,80."""
    w, top, bot, rx = 0.39, 0.52, 1.80, 0.17
    body = f'x="{-w}" y="{top}" width="{2*w}" height="{bot-top}" rx="{rx}"'
    return f"""
  <g stroke-linejoin="round" stroke-linecap="round">
    <path d="M-0.27,0.42 C-0.27,0.29 -0.17,0.25 -0.095,0.215 L-0.095,0.115
             A0.095,0.095 0 0 1 0.095,0.115 L0.095,0.215 C0.17,0.25 0.27,0.29 0.27,0.42 Z"
          fill="{teat}" stroke="{outline}" stroke-width="{stroke}"/>
    <rect {body} fill="{glass}"/>
    <clipPath id="body{c}"><rect {body}/></clipPath>
    <g clip-path="url(#body{c})">
      <path d="M-0.5,1.06 C-0.33,0.98 -0.19,0.98 -0.04,1.05 C0.11,1.12 0.25,1.12 0.5,1.02 L0.5,1.9 L-0.5,1.9 Z" fill="{milk}"/>
      <circle cx="0.14" cy="1.44" r="0.07" fill="{bubble}"/>
      <circle cx="-0.08" cy="1.60" r="0.042" fill="{bubble}"/>
      <circle cx="0.22" cy="1.24" r="0.034" fill="{bubble}"/>
    </g>
    <path d="M{-w},0.80 h0.17 M{-w},1.06 h0.11 M{-w},1.32 h0.17" stroke="{outline}" stroke-width="{stroke*0.8}" fill="none"/>
    <rect {body} fill="none" stroke="{outline}" stroke-width="{stroke}"/>
    <rect x="-0.46" y="0.40" width="0.92" height="0.15" rx="0.065" fill="{collar}" stroke="{outline}" stroke-width="{stroke}"/>
  </g>"""


def app_icon(name, bg_top, bg_bottom, cmd, b, shadow=0.28, ring=None):
    S = 1024
    sq = squircle(512, 512, 412)
    cmd_svg = f'<path d="{command_path(40, 46)}" fill="none" stroke="{cmd}" stroke-width="30" stroke-linejoin="round"/>'
    rim = f'<path d="{sq}" fill="none" stroke="{ring}" stroke-width="3" opacity="0.6"/>' if ring else ""
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="{S}" height="{S}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{bg_top}"/><stop offset="1" stop-color="{bg_bottom}"/>
    </linearGradient>
    <filter id="drop" x="-10%" y="-10%" width="120%" height="125%">
      <feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#000" flood-opacity="{shadow}"/>
    </filter>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="10" stdDeviation="10" flood-color="#000" flood-opacity="0.16"/>
    </filter>
  </defs>
  <path d="{sq}" fill="url(#bg)" filter="url(#drop)"/>
  {rim}
  <g filter="url(#soft)">
    <g transform="translate(330 512)">{cmd_svg}</g>
    <g transform="translate(668 512) rotate(12) scale(300) translate(0 -0.93)">{bottle(**b, stroke=0.05)}</g>
  </g>
</svg>"""
    (OUT / f"{name}.svg").write_text(svg)


# Variante « Jour » : papier crème, ⌘ bleu Oxford, biberon clair et rieur.
app_icon("icon-jour", DAY["raised"], DAY["s2"], DAY["oxford"],
         dict(c=1, glass="#ffffff", milk=DAY["paper"], teat=DAY["claretB"], collar=DAY["oxford"],
              outline=DAY["slate"], bubble=DAY["s2"]), shadow=0.22)
# Variante « Océan » : fond bleu Oxford, ⌘ et biberon couleur papier.
app_icon("icon-ocean", DAY["oxfordB"], DAY["oxford"], DAY["paper"],
         dict(c=2, glass="#ffffff33", milk=DAY["paper"], teat=DAY["claretB"], collar=DAY["paper"],
              outline=DAY["paper"], bubble=DAY["s2"]))
# Variante « Nuit » : papier nuit, ⌘ blé, accents nuit.
app_icon("icon-nuit", NIGHT["s2"], NIGHT["paper"], NIGHT["wheat"],
         dict(c=3, glass="#ffffff14", milk=NIGHT["ink"], teat=NIGHT["claret"], collar=NIGHT["oxford"],
              outline=NIGHT["wheat"], bubble=NIGHT["s2"]), ring="#ffffff22")


def menubar(name, scale=1):
    """Picto modèle (template) 18×18 pt : noir + alpha, macOS le teinte."""
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" width="{18*scale}" height="{18*scale}">
  <path d="M6.9,5.7 C6.9,4.75 7.65,4.3 8.3,4.0 L8.3,2.55 A0.7,0.7 0 0 1 9.7,2.55 L9.7,4.0 C10.35,4.3 11.1,4.75 11.1,5.7 Z" fill="#000"/>
  <rect x="5.1" y="6.2" width="7.8" height="1.7" rx="0.75" fill="#000"/>
  <g fill="none" stroke="#000" stroke-width="1.3" stroke-linejoin="round" stroke-linecap="round">
    <path d="M6.0,7.9 L6.0,15.0 A1.6,1.6 0 0 0 7.6,16.6 L10.4,16.6 A1.6,1.6 0 0 0 12.0,15.0 L12.0,7.9"/>
    <path d="M6.0,12.0 C7.0,11.35 8.0,11.35 9.0,12.0 C10.0,12.65 11.0,12.65 12.0,12.0" stroke-width="1.1"/>
  </g>
</svg>"""
    (OUT / f"{name}.svg").write_text(svg)


menubar("menubar-bottle")
