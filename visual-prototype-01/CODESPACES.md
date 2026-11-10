# Codespaces browser testing

Download and extract the latest Visual Prototype 01 touch ZIP in the Codespaces repository root. The ZIP contains the full playable Godot project, including binary artwork. This GitHub folder contains text source/reference only; the ZIP is needed for images.

Install Godot 4.5.2 on Linux x86_64:

```bash
sudo apt-get update && sudo apt-get install -y unzip wget python3 libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxi6 libxrandr2 libxrender1 libgl1 libasound2
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/godot/export_templates/4.5.2.stable"
cd /tmp
wget -q --show-progress https://github.com/godotengine/godot/releases/download/4.5.2-stable/Godot_v4.5.2-stable_linux.x86_64.zip
unzip -o Godot_v4.5.2-stable_linux.x86_64.zip
install -m 755 Godot_v4.5.2-stable_linux.x86_64 "$HOME/.local/bin/godot"
export PATH="$HOME/.local/bin:$PATH"
godot --version
wget -q --show-progress https://github.com/godotengine/godot/releases/download/4.5.2-stable/Godot_v4.5.2-stable_export_templates.tpz
unzip -o Godot_v4.5.2-stable_export_templates.tpz 'templates/*' -d /tmp/godot-templates
cp /tmp/godot-templates/templates/* "$HOME/.local/share/godot/export_templates/4.5.2.stable/"
```

Upload `Unfortunate_Events_Visual_Prototype_01_touch.zip` to Codespaces then run from the repository root:

```bash
unzip -o Unfortunate_Events_Visual_Prototype_01_touch.zip
cd Unfortunate_Events_Visual_Prototype_01
mkdir -p build
godot --headless --path . --import
godot --headless --path . --export-release Web build/index.html
python3 -m http.server 8000 --directory build --bind 0.0.0.0
```

In Codespaces Ports, open port 8000 in the browser. Choose Public visibility for external testing (Private for yourself). Keep the Codespace and HTTP server running. On mobile, use the full browser tab; the touch overlay appears automatically. Press T to toggle it on desktop. Web preset disables threads to avoid requiring cross-origin isolation.
