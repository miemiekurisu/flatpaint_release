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
  Layers,
  Image as ImageIcon,
  Minus,
  Plus as PlusIcon,
  FileText,
  Droplet,
  Pen
} from "lucide-react";
import { Button } from "./ui/button";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "./ui/tooltip";
import { useState } from "react";
import { Slider } from "./ui/slider";

interface Tool {
  id: string;
  icon: React.ReactNode;
  name: string;
}

const tools: Tool[] = [
  { id: "select", icon: <MousePointer2 className="w-4 h-4" />, name: "选择工具" },
  { id: "move", icon: <Move className="w-4 h-4" />, name: "移动工具" },
  { id: "rectangle", icon: <Square className="w-4 h-4" />, name: "矩形工具" },
  { id: "rounded-rect", icon: <Square className="w-4 h-4" />, name: "圆角矩形" },
  { id: "circle", icon: <Circle className="w-4 h-4" />, name: "圆形工具" },
  { id: "ellipse", icon: <Circle className="w-4 h-4" />, name: "椭圆工具" },
  { id: "line", icon: <Minus className="w-4 h-4" />, name: "直线工具" },
  { id: "curve", icon: <Pen className="w-4 h-4" />, name: "曲线工具" },
  { id: "pencil", icon: <Pencil className="w-4 h-4" />, name: "铅笔工具" },
  { id: "brush", icon: <Paintbrush className="w-4 h-4" />, name: "画笔工具" },
  { id: "fill", icon: <Droplet className="w-4 h-4" />, name: "填充工具" },
  { id: "eraser", icon: <Eraser className="w-4 h-4" />, name: "橡皮擦" },
  { id: "text", icon: <Type className="w-4 h-4" />, name: "文字工具" },
  { id: "eyedropper", icon: <Pipette className="w-4 h-4" />, name: "吸管工具" },
  { id: "wand", icon: <Wand2 className="w-4 h-4" />, name: "魔棒工具" },
  { id: "crop", icon: <Crop className="w-4 h-4" />, name: "裁剪工具" },
  { id: "hand", icon: <Hand className="w-4 h-4" />, name: "抓手工具" },
  { id: "zoom", icon: <ZoomIn className="w-4 h-4" />, name: "缩放工具" },
];

export function ToolPanel() {
  const [selectedTool, setSelectedTool] = useState("brush");
  const [primaryColor, setPrimaryColor] = useState("#000000");
  const [secondaryColor, setSecondaryColor] = useState("#FFFFFF");

  return (
    <div className="w-48 bg-zinc-50 border-r border-zinc-300 flex flex-col">
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
                    className={`h-10 w-full ${
                      selectedTool === tool.id
                        ? "bg-blue-500 text-white hover:bg-blue-600 shadow-sm"
                        : "text-zinc-700 hover:bg-zinc-200"
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

      <div className="h-px bg-zinc-300 mx-2" />

      {/* Colors Section */}
      <div className="p-3">
        <div className="text-xs font-medium text-zinc-700 mb-2">Colors</div>
        
        {/* Primary and Secondary Colors */}
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className="relative w-12 h-12">
              <div 
                className="absolute top-0 left-0 w-9 h-9 border-2 border-white rounded-lg shadow-md cursor-pointer"
                style={{ backgroundColor: primaryColor }}
                onClick={() => document.getElementById('primary-color')?.click()}
              />
              <div 
                className="absolute bottom-0 right-0 w-9 h-9 border-2 border-zinc-400 rounded-lg shadow-md cursor-pointer bg-white"
                style={{ backgroundColor: secondaryColor }}
                onClick={() => document.getElementById('secondary-color')?.click()}
              />
              <input 
                id="primary-color" 
                type="color" 
                value={primaryColor}
                onChange={(e) => setPrimaryColor(e.target.value)}
                className="hidden"
              />
              <input 
                id="secondary-color" 
                type="color" 
                value={secondaryColor}
                onChange={(e) => setSecondaryColor(e.target.value)}
                className="hidden"
              />
            </div>
          </div>
          
          <div className="flex gap-1">
            <Button 
              variant="outline" 
              size="sm" 
              className="h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
              onClick={() => {
                const temp = primaryColor;
                setPrimaryColor(secondaryColor);
                setSecondaryColor(temp);
              }}
            >
              Swap
            </Button>
            <Button 
              variant="outline" 
              size="sm" 
              className="h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
              onClick={() => document.getElementById('color-picker-dialog')?.click()}
            >
              More...
            </Button>
          </div>
        </div>

        {/* RGB Values */}
        <div className="space-y-2 mb-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">R:</span>
            <input 
              type="number" 
              defaultValue="0"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">G:</span>
            <input 
              type="number" 
              defaultValue="0"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">B:</span>
            <input 
              type="number" 
              defaultValue="0"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">A:</span>
            <input 
              type="number" 
              defaultValue="255"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Hex Value */}
        <div className="flex items-center gap-2 mb-3">
          <span className="text-xs text-zinc-600 w-4">#:</span>
          <input 
            type="text" 
            value={primaryColor.replace('#', '')}
            onChange={(e) => setPrimaryColor('#' + e.target.value)}
            className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500 uppercase"
            maxLength={6}
          />
        </div>

        <div className="text-xs text-zinc-500 mb-2">Secondary: #{secondaryColor.replace('#', '')}</div>

        {/* Color Picker Circle */}
        <div className="relative w-32 h-32 mx-auto mb-3">
          <div className="w-full h-full rounded-full bg-gradient-conic from-red-500 via-yellow-500 via-green-500 via-cyan-500 via-blue-500 via-purple-500 to-red-500 shadow-inner" />
          <div className="absolute top-1/2 left-1/2 w-4 h-4 -mt-2 -ml-2 border-2 border-white rounded-full shadow-md pointer-events-none" />
        </div>

        {/* Color Palette */}
        <div className="grid grid-cols-8 gap-1">
          {[
            '#000000', '#404040', '#800000', '#FF0000',
            '#FF8000', '#FFFF00', '#00FF00', '#00FFFF',
            '#0000FF', '#8000FF', '#FF00FF', '#808080',
            '#C0C0C0', '#FFFFFF', '#800080', '#008080',
          ].map((color, i) => (
            <button
              key={i}
              className="w-5 h-5 rounded border border-zinc-300 hover:scale-110 transition-transform"
              style={{ backgroundColor: color }}
              onClick={() => setPrimaryColor(color)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}