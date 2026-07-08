import type { APIRoute } from "astro";
import { renderOgImage } from "./_render";

export const GET: APIRoute = () => renderOgImage("Privacy Policy", "How Squint handles your data");
