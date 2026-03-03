import { 
  Menu, 
  Save, 
  FolderOpen, 
  FileDown, 
  Undo, 
  Redo, 
  Copy, 
  Scissors, 
  ClipboardPaste,
  ZoomIn,
  ZoomOut,
  Palette,
  Layers,
  History,
  Wrench
} from "lucide-react";
import { Button } from "./ui/button";

interface TopMenuBarProps {
  onToggleTools: () => void;
  onToggleColors: () => void;
  onToggleHistory: () => void;
  onToggleLayers: () => void;
}

export function TopMenuBar({ onToggleTools, onToggleColors, onToggleHistory, onToggleLayers }: TopMenuBarProps) {
  return (
    <div className="bg-zinc-100 border-b border-zinc-300">
      {/* macOS Window Controls */}
      <div className="h-11 flex items-center px-3">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded-full bg-red-500 hover:bg-red-600 transition-colors cursor-pointer" />
          <div className="w-3 h-3 rounded-full bg-yellow-500 hover:bg-yellow-600 transition-colors cursor-pointer" />
          <div className="w-3 h-3 rounded-full bg-green-500 hover:bg-green-600 transition-colors cursor-pointer" />
        </div>
        
        <div className="flex-1 text-center">
          <span className="text-zinc-700 text-sm font-medium">PhotoEditor - Untitled (Edited)</span>
        </div>
        
        <div className="w-[60px]" /> {/* Spacer to balance the layout */}
      </div>

      {/* Toolbar */}
      <div className="h-12 bg-white border-t border-zinc-200 flex items-center px-3 gap-2">
        {/* File Operations */}
        <div className="flex items-center gap-1 bg-zinc-100 rounded-lg p-1">
          <Button 
            variant="ghost" 
            size="sm" 
            className="h-7 px-3 text-xs text-zinc-700 hover:bg-white hover:text-zinc-900 rounded-md"
          >
            <FolderOpen className="w-3.5 h-3.5 mr-1.5" />
            New
          </Button>
          <Button 
            variant="ghost" 
            size="sm" 
            className="h-7 px-3 text-xs text-zinc-700 hover:bg-white hover:text-zinc-900 rounded-md"
          >
            <FolderOpen className="w-3.5 h-3.5 mr-1.5" />
            Open
          </Button>
          <Button 
            variant="ghost" 
            size="sm" 
            className="h-7 px-3 text-xs text-zinc-700 hover:bg-white hover:text-zinc-900 rounded-md"
          >
            <Save className="w-3.5 h-3.5 mr-1.5" />
            Save
          </Button>
        </div>

        <div className="w-px h-6 bg-zinc-300" />

        {/* Edit Operations */}
        <div className="flex items-center gap-1">
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <Scissors className="w-4 h-4" />
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <Copy className="w-4 h-4" />
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <ClipboardPaste className="w-4 h-4" />
          </Button>
        </div>

        <div className="w-px h-6 bg-zinc-300" />

        {/* Undo/Redo */}
        <div className="flex items-center gap-1">
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <Undo className="w-4 h-4" />
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <Redo className="w-4 h-4" />
          </Button>
        </div>

        <div className="w-px h-6 bg-zinc-300" />

        {/* Panel Toggles */}
        <div className="flex items-center gap-1">
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
            onClick={onToggleTools}
          >
            <Wrench className="w-4 h-4" />
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
            onClick={onToggleColors}
          >
            <Palette className="w-4 h-4" />
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
            onClick={onToggleHistory}
          >
            <History className="w-4 h-4" />
          </Button>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
            onClick={onToggleLayers}
          >
            <Layers className="w-4 h-4" />
          </Button>
        </div>

        <div className="w-px h-6 bg-zinc-300" />

        {/* Tool Properties */}
        <div className="flex items-center gap-2">
          <span className="text-xs text-zinc-600">Tool:</span>
          <select className="h-7 px-2 text-xs bg-white border border-zinc-300 rounded-md text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500">
            <option>Brush</option>
            <option>Pencil</option>
            <option>Eraser</option>
          </select>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-zinc-600">Size:</span>
          <input 
            type="number" 
            defaultValue="3" 
            className="w-14 h-7 px-2 text-xs bg-white border border-zinc-300 rounded-md text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-zinc-600">Opacity:</span>
          <input 
            type="number" 
            defaultValue="100" 
            className="w-14 h-7 px-2 text-xs bg-white border border-zinc-300 rounded-md text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="ml-auto flex items-center gap-2">
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <ZoomOut className="w-4 h-4" />
          </Button>
          <div className="flex items-center gap-1 bg-white border border-zinc-300 rounded-md px-2 h-7">
            <span className="text-xs text-zinc-700 font-medium">100%</span>
            <select className="text-xs bg-transparent border-none text-zinc-700 focus:outline-none w-4">
              <option>100%</option>
              <option>75%</option>
              <option>50%</option>
            </select>
          </div>
          <Button 
            variant="ghost" 
            size="icon" 
            className="h-8 w-8 text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 rounded-lg"
          >
            <ZoomIn className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}