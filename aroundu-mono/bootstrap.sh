# bootstrap.sh set -euo pipefail

# 0) prerequisites you handle once per 
machine # brew install pnpm python@3.12 uv 
git pre-commit || true

# 1) repo git init printf "# 
aroundu-mono\n\nMono repo for AroundU web, 
API, shared types, and infra.\n" > 
README.md

# 2) workspaces cat > package.json <<'JSON' 
{
  "name": "aroundu-mono", "private": true, 
  "version": "0.1.0", "packageManager": 
  "pnpm@9.6.0", "workspaces": [
    "apps/*", "packages/*"
  ], "scripts": {
    "build": "pnpm -r build", "typecheck": 
    "pnpm -r typecheck", "lint": "pnpm -r 
    lint"
  }, "devDependencies": {
    "prettier": "^3.3.3"
  } } JSON

cat > pnpm-workspace.yaml <<'YAML' 
packages:
  - "apps/*" - "packages/*" YAML

# 3) shared types package mkdir -p 
packages/types/src cat > 
packages/types/package.json <<'JSON' {
  "name": "@aroundu/types", "version": 
  "0.1.0", "type": "module", "exports": {
    ".": "./src/index.ts"
  }, "devDependencies": {
    "typescript": "^5.5.4"
  }, "scripts": {
    "build": "tsc -p tsconfig.json", 
    "typecheck": "tsc -p tsconfig.json
--noEmit",
    "lint": "echo 'no lint yet'"
  } } JSON cat > 
packages/types/tsconfig.json <<'JSON' {
  "extends": "../../tsconfig.base.json", 
  "compilerOptions": {
    "outDir": "dist"
  }, "include": ["src/**/*.ts"] } JSON cat 
> packages/types/src/index.ts <<'TS' export 
type PinType = "brain" | "lifesaver" | 
"leaf"; export interface MapPoint {
  id: string; name: string; type: PinType; 
  lat: number; lng: number; tags?: 
  string[];
} TS

# 4) base tsconfig and prettier cat > 
tsconfig.base.json <<'JSON' {
  "compilerOptions": {
    "target": "ES2022", "module": "ESNext", 
    "moduleResolution": "Bundler", 
    "strict": true, "skipLibCheck": true, 
    "resolveJsonModule": true, "jsx": 
    "react-jsx"
  } } JSON

echo '{}' > .prettierrc

# 5) web app scaffold via Next 14 mkdir -p 
apps pnpm dlx create-next-app@latest 
apps/web --ts --eslint --tailwind --app 
--src-dir --no-experimental-app 
--import-alias "@/*" <<EOF y EOF

# Add minimal map page placeholder and 
points file mkdir -p apps/web/public/data 
cat > 
apps/web/public/data/points.example.geojson 
<<'JSON' {
  "type": "FeatureCollection", "features": 
  [
    { 
"type":"Feature","properties":{"id":"1","name":"Community 
Center","type":"brain"},"geometry":{"type":"Point","coordinates":[-74.1724,40.7357]}},
    { 
"type":"Feature","properties":{"id":"2","name":"Food 
Pantry","type":"lifesaver"},"geometry":{"type":"Point","coordinates":[-74.18,40.73]}},
    { 
"type":"Feature","properties":{"id":"3","name":"Urban 
Farm","type":"leaf"},"geometry":{"type":"Point","coordinates":[-74.16,40.74]}}
  ] } JSON

# Simple map page with placeholder UI cat > 
apps/web/src/app/map/page.tsx <<'TSX' "use 
client"; import { useEffect, useState } 
from "react"; import type { MapPoint } from 
"@aroundu/types";

type Filter = "brain" | "lifesaver" | 
"leaf" | "all";

export default function MapPage() {
  const [filter, setFilter] = 
useState<Filter>("all");
  const [points, setPoints] = 
useState<MapPoint[]>([]);

  useEffect(() => {
    fetch("/data/points.example.geojson")
      .then(r => r.json()) .then(fc => {
        const ps: MapPoint[] = 
fc.features.map((f: any) => ({
          id: f.properties.id, name: 
          f.properties.name, type: 
          f.properties.type, lat: 
          f.geometry.coordinates[1], lng: 
          f.geometry.coordinates[0]
        })); setPoints(ps);
      });
  }, []);

  const visible = points.filter(p => filter 
=== "all" ? true : p.type === filter);

  return (
    <main className="p-6 space-y-4">
      <h1 className="text-2xl 
font-bold">AroundU Map</h1>
      <div className="flex gap-2">
        <button 
onClick={()=>setFilter("all")} 
className={`px-3 py-1 rounded border 
${filter==="all"?"bg-gray-100":""}`}>All</button>
        <button 
onClick={()=>setFilter("brain")} 
className={`px-3 py-1 rounded border 
${filter==="brain"?"bg-gray-100":""}`}>🧠</button>
        <button 
onClick={()=>setFilter("lifesaver")} 
className={`px-3 py-1 rounded border 
${filter==="lifesaver"?"bg-gray-100":""}`}>🛟</button>
        <button 
onClick={()=>setFilter("leaf")} 
className={`px-3 py-1 rounded border 
${filter==="leaf"?"bg-gray-100":""}`}>🌿</button>
      </div> <div className="rounded border 
      p-4">
        <p className="mb-2 text-sm 
text-gray-600">Placeholder map. Pins render 
as a list until Leaflet integration ticket 
ships.</p>
        <ul className="list-disc pl-6">
          {visible.map(p => (
            <li key={p.id}>
              {p.name} • {p.type} • 
{p.lat.toFixed(4)}, {p.lng.toFixed(4)}
            </li>
          ))}
        </ul>
      </div>
    </main>
  ); } TSX

# wire types package to web pnpm -C 
apps/web add @aroundu/types --save-dev # 
ensure local resolution cat > 
apps/web/package.json <<'JSON' {
  "name": "web", "version": "0.1.0", 
  "private": true, "scripts": {
    "dev": "next dev", "build": "next 
    build", "start": "next start", "lint": 
    "next lint", "typecheck": "tsc -p 
    tsconfig.json
--noEmit"
  }, "dependencies": {
    "next": "14.2.5", "react": "^18", 
    "react-dom": "^18"
  }, "devDependencies": {
    "@types/node": "^20", "@types/react": 
    "^18", "@types/react-dom": "^18", 
    "autoprefixer": "^10", "postcss": "^8", 
    "tailwindcss": "^3.4.7", "typescript": 
    "^5.5.4", "@aroundu/types": 
    "workspace:*"
  } } JSON

# 6) API app with FastAPI mkdir -p 
apps/api/app cat > apps/api/pyproject.toml 
<<'TOML' [project] name = "aroundu-api" 
version = "0.1.0" requires-python = 
">=3.12" dependencies = 
["fastapi>=0.111.0", "uvicorn>=0.30.0", 
"pydantic>=2.7.0", "httpx>=0.27.0"]

[tool.uv] system-site-packages = false TOML

cat > apps/api/app/main.py <<'PY' from 
fastapi import FastAPI from pydantic import 
BaseModel

app = FastAPI(title="AroundU API")

class Health(BaseModel):
    status: str = "ok"

@app.get("/health", response_model=Health) 
def health():
    return Health() PY

# simple run script cat > 
apps/api/README.md <<'MD' Run: ```bash uv 
venv uv pip install -r <(uv pip compile -q 
pyproject.toml) uv run uvicorn app.main:app 
--reload --port 8000

