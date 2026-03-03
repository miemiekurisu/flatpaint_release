import { TopMenuBar } from "./components/TopMenuBar";
import { CanvasArea } from "./components/CanvasArea";
import { FloatingToolbar } from "./components/FloatingToolbar";
import { FloatingColorPanel } from "./components/FloatingColorPanel";
import { FloatingHistoryPanel } from "./components/FloatingHistoryPanel";
import { FloatingLayersPanel } from "./components/FloatingLayersPanel";
import { useState } from "react";

export default function App() {
  const [showTools, setShowTools] = useState(true);
  const [showColors, setShowColors] = useState(true);
  const [showHistory, setShowHistory] = useState(true);
  const [showLayers, setShowLayers] = useState(true);

  return (
    <div className="h-screen w-screen flex flex-col bg-zinc-100 text-zinc-900 overflow-hidden">
      {/* Top Menu Bar with macOS style */}
      <TopMenuBar 
        onToggleTools={() => setShowTools(!showTools)}
        onToggleColors={() => setShowColors(!showColors)}
        onToggleHistory={() => setShowHistory(!showHistory)}
        onToggleLayers={() => setShowLayers(!showLayers)}
      />

      {/* Main Content Area - Full Canvas */}
      <div className="flex-1 flex overflow-hidden relative">
        <CanvasArea />

        {/* Floating Panels */}
        {showTools && <FloatingToolbar onClose={() => setShowTools(false)} />}
        {showColors && <FloatingColorPanel onClose={() => setShowColors(false)} />}
        {showHistory && <FloatingHistoryPanel onClose={() => setShowHistory(false)} />}
        {showLayers && <FloatingLayersPanel onClose={() => setShowLayers(false)} />}
      </div>
    </div>
  );
}