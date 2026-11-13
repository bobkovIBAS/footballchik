"""Render the hand-drawn HUD illustrations and pack one local Studio atlas."""
from base64 import b64encode
from pathlib import Path
import io
import subprocess
from PIL import Image
import zstandard

HERE = Path(__file__).resolve().parent
CLIENT = HERE.parents[1] / "src/client/UIV2"
SIZE = 112
ICONS = {
    "Coins": ("#fff98e", "#ffbb22", "#e6650b", """
        <ellipse cx="58" cy="103" rx="40" ry="7" fill="#392041" opacity=".28" stroke="none"/>
        <path d="M16 74v15c0 9 15 15 35 15s36-7 36-15V74" fill="#e37910"/>
        <ellipse cx="51" cy="74" rx="35" ry="14" fill="url(#paint)"/>
        <path d="M20 59v12c0 8 13 13 31 13s32-5 32-13V59" fill="#e48410"/>
        <ellipse cx="51" cy="60" rx="31" ry="13" fill="#ffe167"/>
        <ellipse cx="61" cy="42" rx="34" ry="34" fill="#db720f" transform="rotate(-14 61 42)"/>
        <ellipse cx="56" cy="39" rx="30" ry="32" fill="url(#paint)" transform="rotate(-14 56 39)"/>
        <ellipse cx="56" cy="39" rx="22" ry="24" fill="none" stroke="#b9610a" stroke-width="3"/>
        <path d="m55 20 5 12 13 2-9 9 2 13-11-6-11 6 2-13-9-9 13-2z" fill="#fff5aa" stroke="#bf6810" stroke-width="2"/>
        <path d="M37 28q4-9 13-12" stroke="#fffbd1" stroke-width="3" fill="none"/>
        <path d="M92 15v16m-8-8h16" stroke="#fff4ba" stroke-width="3"/>
    """),
    "Power": ("#e1fbff", "#42d9ff", "#2454e0", """
        <ellipse cx="55" cy="103" rx="37" ry="6" fill="#161954" opacity=".23" stroke="none"/>
        <path d="M57 10 21 59h28l-7 42 52-60H65l17-31z" fill="#253eb3" transform="translate(5 2)"/>
        <path d="M55 8 20 56h28l-8 43 52-59H63L80 8z" fill="url(#paint)"/>
        <path d="m55 16-23 32h16M66 15h5" fill="none" stroke="#edffff" stroke-width="4"/>
        <path d="M18 25v15m-7-7h14m82 30v14m-7-7h14" stroke="#d7f8ff" stroke-width="3"/>
    """),
    "Shop": ("#ffabb0", "#fa4052", "#ae1940", """
        <ellipse cx="54" cy="96" rx="44" ry="8" fill="#442345" opacity=".28" stroke="none"/>
        <path d="M13 69v14l11 5 2 10h10l2-8 18 1 2 8h10l3-9 14-2 3 7h10l4-12V70z" fill="#eef5ff"/>
        <path d="M11 73q1-11 15-14l15-3 12-13 5-20 20 7 8-11 12 6 3 42 3 10q-3 11-27 14H33q-25-4-22-18z" fill="url(#paint)"/>
        <path d="M14 75q15 10 54 7 20-2 33-10v11q-8 9-30 10H30q-18-3-18-10z" fill="#f8f4fa" stroke-width="3"/>
        <path d="m52 46 15 7m-22 0 15 7m-24-1 16 8" fill="none" stroke="#fff2ee" stroke-width="4"/>
        <path d="m70 68 14-23 10-6-8 22z" fill="#ffde69" stroke="#9a2a37" stroke-width="2"/>
        <path d="M20 71q7-7 16-6m31-33 8 4" stroke="#ffd3c4" stroke-width="3" fill="none"/>
    """),
    "Team": ("#a6efff", "#398cff", "#273dbd", """
        <path d="M46 25q-7 0-18-9L7 33l11 24 13-6-2 46 56 1-2-45 12 5 12-24-23-18q-10 8-18 9z" fill="#303ea4" transform="translate(1 5)"/>
        <path d="M45 20q-8 0-17-7L7 31l11 24 13-6-2 46h56l-2-46 12 6 12-24-23-18q-9 7-17 7z" fill="url(#paint)"/>
        <path d="M37 17q6 19 19 20t20-20l-10 2q-4 9-10 9t-11-9z" fill="#edf8ff" stroke-width="2"/>
        <path d="m12 31 11 20m79-20L92 50M31 88h51" stroke="#e7f5ff" stroke-width="4"/>
        <path d="M33 24q-8 5-11 12m15 13-2 27" fill="none" stroke="#c9faff" stroke-width="3"/>
        <path d="m48 48-8 5v6l8-3v23h8V48zm24 0q-11 0-11 9v14q0 8 11 8 10 0 10-8V57q0-9-10-9zm0 7q3 0 3 4v10q0 4-3 4t-3-4V59q0-4 3-4z" fill="#f8fbff" stroke-width="1.5"/>
    """),
    "Progress": ("#f0bbff", "#aa54fc", "#6431c0", """
        <path d="M25 19h61q10 0 10 10v63q0 11-10 11H25q-11 0-11-11V29q0-10 11-10z" fill="#552b9e" transform="translate(2 3)"/>
        <path d="M22 18h62q10 0 10 10v61q0 10-10 10H22q-10 0-10-10V28q0-10 10-10z" fill="url(#paint)"/>
        <path d="M22 38h61v49H22z" fill="#faf0ff" stroke="#54318a" stroke-width="3"/>
        <path d="M37 17h8q0-9 9-9t9 9h10v18H37z" fill="#ffe270" stroke-width="3"/>
        <path d="m30 50 4 4 8-9m-12 18 4 4 8-9m-12 18 4 4 8-9" fill="none" stroke="#8044d6" stroke-width="3"/>
        <path d="M49 51h23m-23 13h23m-23 13h13" stroke="#b09ac8" stroke-width="3"/>
        <path d="m86 66 5 10 12 2-9 7 2 11-10-5-10 5 2-11-9-7 12-2z" fill="#fff079" stroke="#592b8f" stroke-width="2.5"/>
    """),
    "Settings": ("#f0f6ff", "#a0b2d0", "#5e6f94", """
        <path d="M44 10h23l3 12 8 4 12-4 13 16-7 10 2 10 10 6-5 19-13 1-7 6-3 13H57l-6-10-10-1-11 6-15-14 4-12-4-9-12-4 2-20 13-4 6-8-2-13 17-8z" fill="#65799b" transform="translate(0 3)"/>
        <path d="M44 8h23l3 12 8 4 12-4 13 16-7 10 2 10 10 6-5 19-13 1-7 6-3 13H57l-6-10-10-1-11 6-15-14 4-12-4-9-12-4 2-20 13-4 6-8-2-13 17-8z" fill="url(#paint)"/>
        <circle cx="55" cy="55" r="25" fill="#65749c" stroke-width="3"/>
        <circle cx="55" cy="55" r="17" fill="#f2f9ff" stroke-width="3"/>
        <path d="M35 45q5-10 14-11m0-22h12" stroke="#fff" stroke-width="3" fill="none"/>
    """),
    "Ball": ("#ffffff", "#e5effe", "#9caed1", """
        <path d="m4 61 21-13m-14 32 17-9M17 94l17-12" fill="none" stroke="#85f0a2" stroke-width="4"/>
        <circle cx="65" cy="52" r="40" fill="#5b688f" transform="translate(1 4)"/>
        <circle cx="65" cy="52" r="40" fill="url(#paint)"/>
        <g clip-path="url(#ballclip)" fill="#354260" stroke="#272840" stroke-width="1.5">
            <path d="m65 34 16 12-6 19H55l-6-19zM34 19l17-7 8 12-14 12-15-4zM90 18l14 13-2 16-14 1-8-16zM103 59l6 18-18 13-9-12 7-14zM35 59l11 17-7 13-19-12 3-16zM54 82h21l8 16-36 1z"/>
            <path d="m64 35-5-11m-10 22-19-14m25 33-9 11m29-11 7 13m-1-32 7 2" fill="none" stroke="#7186ad" stroke-width="2"/>
        </g>
        <path d="M39 40q6-15 18-17" fill="none" stroke="#fff" stroke-width="3"/>
        <path d="M18 26v12m-6-6h12" stroke="#fcffae" stroke-width="3"/>
    """),
    "GoldBall": ("#fffba1", "#ffd345", "#e47b0b", """
        <circle cx="56" cy="56" r="40" fill="#b9660d" transform="translate(0 4)"/>
        <circle cx="56" cy="54" r="40" fill="url(#paint)"/>
        <path d="m56 30 20 15-7 24H43l-7-24z" fill="#fff5a1" stroke="#bf6910" stroke-width="3"/>
        <path d="m56 30-2-15M36 45 21 37m22 32L32 85m37-16 11 16m-4-40 15-8" fill="none" stroke="#bc6715" stroke-width="3"/>
        <path d="M37 29q6-7 14-8m44-7v16m-8-8h16M13 74v12m-6-6h12" stroke="#fff6ac" fill="none" stroke-width="3"/>
    """),
    "Menu": ("#a5d4ff", "#5387ef", "#5946ba", """
        <path d="M20 25h72v62H20z" fill="url(#paint)" stroke-width="5" rx="15"/>
        <path d="M37 42h39M37 56h39M37 70h30" stroke="#fff4fe" stroke-width="7"/>
        <path d="M30 33h21" stroke="#ceefff" stroke-width="3"/>
    """),
}


def artwork(icon):
    top, mid, bottom, shapes = icon
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 112 112">
      <defs><linearGradient id="paint" x2=".22" y2="1" gradientUnits="objectBoundingBox">
        <stop stop-color="{top}"/><stop offset=".47" stop-color="{mid}"/><stop offset="1" stop-color="{bottom}"/>
      </linearGradient><clipPath id="ballclip"><circle cx="65" cy="52" r="39"/></clipPath></defs>
      <g stroke="#29213e" stroke-width="3.8" stroke-linecap="round" stroke-linejoin="round">{shapes}</g></svg>"""


def main():
    atlas = Image.new("RGBA", (SIZE * 3, SIZE * 3))
    for i, icon in enumerate(ICONS.values()):
        renderer = """const {Resvg}=require('@resvg/resvg-js');
            const svg=require('node:fs').readFileSync(0,'utf8');
            process.stdout.write(new Resvg(svg,{fitTo:{mode:'width',value:224}}).render().asPng());"""
        png = subprocess.check_output(["node", "-e", renderer], input=artwork(icon).encode(), cwd=HERE)
        source = Image.open(io.BytesIO(png))
        atlas.paste(source.resize((SIZE, SIZE), Image.Resampling.LANCZOS), (i % 3 * SIZE, i // 3 * SIZE))
    atlas.save(HERE / "HudIcons.png", optimize=True)
    compressed = zstandard.ZstdCompressor(level=15).compress(atlas.tobytes())
    encoded = b64encode(compressed).decode()
    lines = [encoded[i:i + 120] for i in range(0, len(encoded), 120)]
    source = "-- Generated by assets/uiv2/build_atlas.py.\nreturn table.concat({\n%s\n})\n"
    (CLIENT / "AtlasData.luau").write_text(source % "\n".join(f'\t"{line}",' for line in lines))


if __name__ == "__main__":
    main()
