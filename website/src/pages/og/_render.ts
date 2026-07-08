import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { Resvg } from "@resvg/resvg-js";
import satori from "satori";

const logoBuffer = readFileSync(resolve(process.cwd(), "src/assets/logo.png"));
const logoDataUri = `data:image/png;base64,${logoBuffer.toString("base64")}`;

let fontRegular: ArrayBuffer | null = null;
let fontBold: ArrayBuffer | null = null;

async function loadFonts() {
    if (!fontRegular) {
        const res = await fetch(
            "https://cdn.jsdelivr.net/fontsource/fonts/inter@latest/latin-400-normal.ttf"
        );
        fontRegular = await res.arrayBuffer();
    }
    if (!fontBold) {
        const res = await fetch(
            "https://cdn.jsdelivr.net/fontsource/fonts/inter@latest/latin-700-normal.ttf"
        );
        fontBold = await res.arrayBuffer();
    }
    return { fontRegular, fontBold };
}

function buildTemplate(title: string, subtitle: string) {
    return {
        type: "div",
        props: {
            style: {
                width: "100%",
                height: "100%",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                backgroundImage: "linear-gradient(180deg, #0b090c 0%, #141117 100%)",
                padding: "80px",
                fontFamily: "Inter",
                color: "white",
            },
            children: [
                {
                    type: "img",
                    props: {
                        src: logoDataUri,
                        width: 180,
                        height: 180,
                        style: { marginBottom: "48px" },
                    },
                },
                {
                    type: "div",
                    props: {
                        style: {
                            fontSize: 88,
                            fontWeight: 700,
                            letterSpacing: "-0.02em",
                            marginBottom: 20,
                            textAlign: "center",
                        },
                        children: title,
                    },
                },
                {
                    type: "div",
                    props: {
                        style: {
                            fontSize: 32,
                            fontWeight: 400,
                            color: "rgba(255,255,255,0.75)",
                            textAlign: "center",
                            maxWidth: "900px",
                            lineHeight: 1.35,
                        },
                        children: subtitle,
                    },
                },
            ],
        },
    };
}

export async function renderOgImage(title: string, subtitle: string): Promise<Response> {
    const { fontRegular, fontBold } = await loadFonts();

    // Satori's React node typings are intentionally loose; we hand it a plain
    // JSX-like tree from buildTemplate(), which is the documented usage pattern.
    // biome-ignore lint/suspicious/noExplicitAny: satori interop boundary
    const svg = await satori(buildTemplate(title, subtitle) as any, {
        width: 1200,
        height: 630,
        fonts: [
            // biome-ignore lint/style/noNonNullAssertion: fonts are loaded synchronously above
            { name: "Inter", data: fontRegular!, weight: 400, style: "normal" },
            // biome-ignore lint/style/noNonNullAssertion: fonts are loaded synchronously above
            { name: "Inter", data: fontBold!, weight: 700, style: "normal" },
        ],
    });

    const png = new Resvg(svg, { background: "#0b090c" }).render().asPng();
    return new Response(new Uint8Array(png), {
        headers: {
            "Content-Type": "image/png",
            "Cache-Control": "public, max-age=31536000, immutable",
        },
    });
}
