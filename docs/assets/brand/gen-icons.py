"""Génère l'identité de CmdBaby : icônes, calques Icon Composer, PNG, PDF et picto de barre de menus.

Écrit dans son propre dossier, quel que soit le dossier courant. Déterministe : relancer ne change rien.
Voir README.md à côté.
"""
import math, os, pathlib, shutil, subprocess, sys, tempfile

OUT = pathlib.Path(__file__).parent
LAYERS = OUT / "layers"

# Palettes camillehdl.dev/palette et /palette-night
DAY = dict(paper="#fff1e5", raised="#fff9f2", s1="#f7e7d8", s2="#f2dfce", slate="#262a33",
           claret="#990f3d", claretB="#bf5f80", oxford="#0f5499", oxfordB="#1e6ec4",
           teal="#0d7680", mandarinB="#bf6626")
NIGHT = dict(paper="#1f1915", raised="#261f1a", s1="#2b231d", s2="#3a2f27", ink="#e3d1bf", wheat="#f2dfce",
             claret="#d28e9b", oxford="#7da5d2", oxfordB="#9ab6d6", mandarin="#d2905f", teal="#4db4ba")

S = 1024
CMD_AT = "translate(330 512)"
BOTTLE_AT = "translate(668 512) rotate(12) scale(300) translate(0 -0.93)"


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


def command(color):
    return f'<path d="{command_path(40, 46)}" fill="none" stroke="{color}" stroke-width="30" stroke-linejoin="round"/>'


def gradient(top, bottom, gid="bg"):
    return f"""<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/>
    </linearGradient>"""


def svg_document(body, width=S, height=S, view=None):
    view = view or f"0 0 {width} {height}"
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}" width="{width}" height="{height}">
{body}
</svg>"""


def app_icon_svg(v, shadows=True):
    """Icône complète. Sans ombres pour le PDF des Réglages : squircle et contenu seulement."""
    sq = squircle(512, 512, 412)
    rim = f'<path d="{sq}" fill="none" stroke="{v["ring"]}" stroke-width="3" opacity="0.6"/>' if v["ring"] else ""
    if not shadows:
        return svg_document(f"""  <defs>
    {gradient(v["top"], v["bottom"])}
  </defs>
  <path d="{sq}" fill="url(#bg)"/>
  {rim}
  <g>
    <g transform="{CMD_AT}">{command(v["cmd"])}</g>
    <g transform="{BOTTLE_AT}">{bottle(**v["bottle"], stroke=0.05)}</g>
  </g>""")
    return svg_document(f"""  <defs>
    {gradient(v["top"], v["bottom"])}
    <filter id="drop" x="-10%" y="-10%" width="120%" height="125%">
      <feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#000" flood-opacity="{v["shadow"]}"/>
    </filter>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="10" stdDeviation="10" flood-color="#000" flood-opacity="0.16"/>
    </filter>
  </defs>
  <path d="{sq}" fill="url(#bg)" filter="url(#drop)"/>
  {rim}
  <g filter="url(#soft)">
    <g transform="{CMD_AT}">{command(v["cmd"])}</g>
    <g transform="{BOTTLE_AT}">{bottle(**v["bottle"], stroke=0.05)}</g>
  </g>""")


# Variante « Jour » : papier crème, ⌘ bleu Oxford, biberon clair et rieur.
JOUR = dict(top=DAY["raised"], bottom=DAY["s2"], cmd=DAY["oxford"], shadow=0.22, ring=None,
            bottle=dict(c=1, glass="#ffffff", milk=DAY["paper"], teat=DAY["claretB"], collar=DAY["oxford"],
                        outline=DAY["slate"], bubble=DAY["s2"]))
# Variante « Océan » : fond bleu Oxford, ⌘ et biberon couleur papier.
OCEAN = dict(top=DAY["oxfordB"], bottom=DAY["oxford"], cmd=DAY["paper"], shadow=0.28, ring=None,
             bottle=dict(c=2, glass="#ffffff33", milk=DAY["paper"], teat=DAY["claretB"], collar=DAY["paper"],
                         outline=DAY["paper"], bubble=DAY["s2"]))
# Variante « Nuit » : papier nuit, ⌘ blé, accents nuit.
NUIT = dict(top=NIGHT["s2"], bottom=NIGHT["paper"], cmd=NIGHT["wheat"], shadow=0.28, ring="#ffffff22",
            bottle=dict(c=3, glass="#ffffff14", milk=NIGHT["ink"], teat=NIGHT["claret"], collar=NIGHT["oxford"],
                        outline=NIGHT["wheat"], bubble=NIGHT["s2"]))
# Calque monochrome d'Icon Composer : blanc pur, lait et bulles à 60 %.
MONO_BOTTLE = dict(c=4, glass="#ffffff", milk="#ffffff99", teat="#ffffff", collar="#ffffff",
                   outline="#ffffff", bubble="#ffffff99")


def layers(name, v):
    """Calques Icon Composer, même repère 1024 que l'icône, sans squircle ni ombre."""
    (LAYERS / f"background-{name}.svg").write_text(svg_document(f"""  <defs>
    {gradient(v["top"], v["bottom"])}
  </defs>
  <rect width="{S}" height="{S}" fill="url(#bg)"/>"""))
    (LAYERS / f"command-{name}.svg").write_text(svg_document(f'  <g transform="{CMD_AT}">{command(v["cmd"])}</g>'))
    (LAYERS / f"bottle-{name}.svg").write_text(
        svg_document(f'  <g transform="{BOTTLE_AT}">{bottle(**v["bottle"], stroke=0.05)}</g>'))


def menubar_svg():
    """Picto modèle (template) 18×18 pt : noir + alpha, macOS le teinte."""
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" width="18" height="18">
  <path d="M6.9,5.7 C6.9,4.75 7.65,4.3 8.3,4.0 L8.3,2.55 A0.7,0.7 0 0 1 9.7,2.55 L9.7,4.0 C10.35,4.3 11.1,4.75 11.1,5.7 Z" fill="#000"/>
  <rect x="5.1" y="6.2" width="7.8" height="1.7" rx="0.75" fill="#000"/>
  <g fill="none" stroke="#000" stroke-width="1.3" stroke-linejoin="round" stroke-linecap="round">
    <path d="M6.0,7.9 L6.0,15.0 A1.6,1.6 0 0 0 7.6,16.6 L10.4,16.6 A1.6,1.6 0 0 0 12.0,15.0 L12.0,7.9"/>
    <path d="M6.0,12.0 C7.0,11.35 8.0,11.35 9.0,12.0 C10.0,12.65 11.0,12.65 12.0,12.0" stroke-width="1.1"/>
  </g>
</svg>"""


def social_preview_svg():
    """1280 × 640, sans texte : le rendu des polices dépend de la machine."""
    icon = app_icon_svg(OCEAN).split("\n", 1)[1].rsplit("\n", 1)[0]
    return svg_document(f"""  <defs>
    {gradient(DAY["oxfordB"], DAY["oxford"], gid="social")}
  </defs>
  <rect width="1280" height="640" fill="url(#social)"/>
  <svg x="420" y="100" width="440" height="440" viewBox="0 0 {S} {S}">
{icon}
  </svg>""", width=1280, height=640)


def rsvg(svg, target, fmt, size=None, page_pt=None):
    """`page_pt` : taille de page du PDF en points. `SOURCE_DATE_EPOCH` fige la date du PDF."""
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as source:
        source.write(svg)
    args = ["rsvg-convert", "-f", fmt, "-o", str(target)]
    if size:
        args += ["-w", str(size[0]), "-h", str(size[1])]
    if page_pt:
        args += ["--page-width", f"{page_pt}pt", "--page-height", f"{page_pt}pt",
                 "-w", f"{page_pt}pt", "-h", f"{page_pt}pt"]
    try:
        subprocess.run(args + [source.name], check=True, env={**os.environ, "SOURCE_DATE_EPOCH": "0"})
    finally:
        os.unlink(source.name)


def main():
    if shutil.which("rsvg-convert") is None:
        sys.exit("Installer librsvg : `brew install librsvg`")
    LAYERS.mkdir(exist_ok=True)

    for name, v in [("icon-jour", JOUR), ("icon-ocean", OCEAN), ("icon-nuit", NUIT)]:
        (OUT / f"{name}.svg").write_text(app_icon_svg(v))

    layers("jour", JOUR)
    layers("nuit", NUIT)
    (LAYERS / "command-mono.svg").write_text(svg_document(f'  <g transform="{CMD_AT}">{command("#ffffff")}</g>'))
    (LAYERS / "bottle-mono.svg").write_text(
        svg_document(f'  <g transform="{BOTTLE_AT}">{bottle(**MONO_BOTTLE, stroke=0.05)}</g>'))

    rsvg(app_icon_svg(JOUR, shadows=False), OUT / "app-icon-jour.pdf", "pdf", page_pt=S)
    rsvg(app_icon_svg(NUIT, shadows=False), OUT / "app-icon-nuit.pdf", "pdf", page_pt=S)
    rsvg(app_icon_svg(JOUR), OUT / "app-icon-1024.png", "png", size=(S, S))
    rsvg(app_icon_svg(NUIT), OUT / "app-icon-1024-dark.png", "png", size=(S, S))
    rsvg(social_preview_svg(), OUT / "social-preview.png", "png", size=(1280, 640))

    (OUT / "menubar-bottle.svg").write_text(menubar_svg())
    rsvg(menubar_svg(), OUT / "menubar-bottle.pdf", "pdf", page_pt=18)


if __name__ == "__main__":
    main()
