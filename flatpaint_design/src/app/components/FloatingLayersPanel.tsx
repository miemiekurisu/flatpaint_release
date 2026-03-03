import { Button } from "./ui/button";
import { 
  GripVertical, 
  X, 
  Plus, 
  Minus, 
  Copy, 
  ChevronDown, 
  Settings, 
  Trash2,
  Eye
} from "lucide-react";
import { ScrollArea } from "./ui/scroll-area";
import { useState } from "react";

interface FloatingLayersPanelProps {
  onClose: () => void;
}

export function FloatingLayersPanel({ onClose }: FloatingLayersPanelProps) {
  const [position, setPosition] = useState({ x: window.innerWidth - 280, y: 330 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

  const handleMouseDown = (e: React.MouseEvent) => {
    if ((e.target as HTMLElement).closest('.drag-handle')) {
      setIsDragging(true);
      setDragOffset({
        x: e.clientX - position.x,
        y: e.clientY - position.y,
      });
    }
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (isDragging) {
      setPosition({
        x: e.clientX - dragOffset.x,
        y: e.clientY - dragOffset.y,
      });
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  useState(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
      return () => {
        window.removeEventListener('mousemove', handleMouseMove);
        window.removeEventListener('mouseup', handleMouseUp);
      };
    }
  });

  return (
    <div
      className="fixed bg-white/95 backdrop-blur-xl rounded-xl shadow-2xl border border-zinc-300/50 overflow-hidden select-none w-64"
      style={{
        left: `${position.x}px`,
        top: `${position.y}px`,
        zIndex: 50,
      }}
      onMouseDown={handleMouseDown}
    >
      {/* Title Bar */}
      <div className="h-8 bg-gradient-to-b from-zinc-100 to-zinc-50 border-b border-zinc-200 flex items-center justify-between px-3 drag-handle cursor-move">
        <GripVertical className="w-3 h-3 text-zinc-400" />
        <span className="text-xs font-medium text-zinc-600">Layers</span>
        <Button
          variant="ghost"
          size="icon"
          className="h-5 w-5 hover:bg-zinc-200 rounded"
          onClick={onClose}
        >
          <X className="w-3 h-3 text-zinc-500" />
        </Button>
      </div>

      {/* Layers Content */}
      <div className="p-3">
        {/* Layer Controls */}
        <div className="flex gap-1 mb-2">
          <Button 
            variant="outline" 
            size="icon" 
            className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <Plus className="w-3.5 h-3.5" />
          </Button>
          <Button 
            variant="outline" 
            size="icon" 
            className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <Minus className="w-3.5 h-3.5" />
          </Button>
          <Button 
            variant="outline" 
            size="icon" 
            className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <Copy className="w-3.5 h-3.5" />
          </Button>
          <Button 
            variant="outline" 
            size="icon" 
            className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <Settings className="w-3.5 h-3.5" />
          </Button>
          <Button 
            variant="outline" 
            size="icon" 
            className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </Button>
        </div>

        {/* Blend Mode */}
        <div className="mb-2">
          <div className="flex items-center gap-2 bg-white border border-zinc-300 rounded-lg p-2">
            <span className="text-xs text-zinc-600 flex-1">Normal</span>
            <ChevronDown className="w-3 h-3 text-zinc-500" />
          </div>
        </div>

        {/* Layers List */}
        <div className="h-40 mb-2">
          <ScrollArea className="h-full">
            <div className="space-y-1">
              <LayerItem 
                name="Background" 
                visible={true}
                selected
              />
            </div>
          </ScrollArea>
        </div>

        {/* Layer Thumbnail */}
        <div className="bg-white border border-zinc-300 rounded-lg p-2 h-28 flex items-center justify-center">
          <div className="w-full h-full bg-[linear-gradient(45deg,#e5e5e5_25%,transparent_25%,transparent_75%,#e5e5e5_75%,#e5e5e5),linear-gradient(45deg,#e5e5e5_25%,transparent_25%,transparent_75%,#e5e5e5_75%,#e5e5e5)] bg-[length:16px_16px] bg-[position:0_0,8px_8px] rounded" />
        </div>
      </div>
    </div>
  );
}

function LayerItem({ 
  name, 
  visible, 
  selected = false 
}: { 
  name: string; 
  visible: boolean; 
  selected?: boolean;
}) {
  return (
    <div 
      className={`flex items-center gap-2 px-2 py-1.5 rounded-lg cursor-pointer group ${
        selected 
          ? "bg-blue-500 text-white" 
          : "bg-white hover:bg-zinc-100 text-zinc-700 border border-zinc-300"
      }`}
    >
      <Eye className="w-3.5 h-3.5" />
      <span className="text-xs flex-1 truncate">{name}</span>
    </div>
  );
}