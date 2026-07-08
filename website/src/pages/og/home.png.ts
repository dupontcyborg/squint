import type { APIRoute } from "astro";
import { renderOgImage } from "./_render";

export const GET: APIRoute = () =>
    renderOgImage("Squint", "Temporarily disable auto-brightness on macOS");
