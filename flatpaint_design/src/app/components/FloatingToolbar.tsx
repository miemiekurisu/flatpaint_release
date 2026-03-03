import { 
  MousePointer2,
  Move,
  Square,
  Circle,
  Type,
  Pencil,
  Paintbrush,
  Eraser,
  Pipette,
  Hand,
  ZoomIn,
  Crop,
  Wand2,
  GripVertical,
  X
} from "lucide-react";
import { Button } from "./ui/button";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "./ui/tooltip";
import { useState } from "react";

interface Tool {
  id: string;
  icon: React.ReactNode;
  name: string;
}

const tools: Tool[] = [
  { id: "select", icon: <MousePointer2 className="w-4 h-4" />, name: "选择工具" },
  { id: "move", icon: <Move className="w-4 h-4" />, name: "移动工具" },
  { id: "rectangle", icon: <Square className="w-4 h-4" />, name: "矩形工具" },
  { id: "circle", icon: <Circle className="w-4 h-4" />, name: "圆形工具" },
  { id: "pencil", icon: <Pencil className="w-4 h-4" />, name: "铅笔工具" },
  { id: "brush", icon: <Paintbrush className="w-4 h-4" />, name: "画笔工具" },
  { id: "eraser", icon: <Eraser className="w-4 h-4" />, name: "橡皮擦" },
  { id: "text", icon: <Type className="w-4 h-4" />, name: "文字工具" },
  { id: "eyedropper", icon: <Pipette className="w-4 h-4" />, name: "吸管工具" },
  { id: "wand", icon: <Wand2 className="w-4 h-4" />, name: "魔棒工具" },
  { id: "crop", icon: <Crop className="w-4 h-4" />, name: "裁剪工具" },
  { id: "hand", icon: <Hand className="w-4 h-4" />, name: "抓手工具" },
  { id: "zoom", icon: <ZoomIn className="w-4 h-4" />, name: "缩放工具" },
];

interface FloatingToolbarProps {
  onClose: () => void;
}

export function FloatingToolbar({ onClose }: FloatingToolbarProps) {
  const [selectedTool, setSelectedTool] = useState("brush");
  const [position, setPosition] = useState({ x: 20, y: 140 });
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
      className="fixed bg-white/95 backdrop-blur-xl rounded-xl shadow-2xl border border-zinc-300/50 overflow-hidden select-none"
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
        <span className="text-xs font-medium text-zinc-600">Tools</span>
        <Button
          variant="ghost"
          size="icon"
          className="h-5 w-5 hover:bg-zinc-200 rounded"
          onClick={onClose}
        >
          <X className="w-3 h-3 text-zinc-500" />
        </Button>
      </div>

      {/* Tools Grid */}
      <div className="p-2">
        <TooltipProvider delayDuration={300}>
          <div className="grid grid-cols-2 gap-1">
            {tools.map((tool) => (
              <Tooltip key={tool.id}>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    className={`h-9 w-9 ${
                      selectedTool === tool.id
                        ? "bg-blue-500 text-white hover:bg-blue-600 shadow-sm"
                        : "text-zinc-700 hover:bg-zinc-100"
                    } rounded-lg`}
                    onClick={() => setSelectedTool(tool.id)}
                  >
                    {tool.icon}
                  </Button>
                </TooltipTrigger>
                <TooltipContent side="right">
                  <p className="text-xs">{tool.name}</p>
                </TooltipContent>
              </Tooltip>
            ))}
          </div>
        </TooltipProvider>
      </div>
    </div>
  );
}