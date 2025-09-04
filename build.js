#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

/**
 * 检测 readline 库的位置和配置
 */
function detectReadlineConfig() {
  const platform = os.platform();
  const arch = os.arch();
  
  let ccFlags = [];
  let ccLinkFlags = [];
  let cc = 'cc'; // 默认编译器
  let useMockImplementation = false;
  
  try {
    // 尝试检测不同的编译器
    const compilers = ['clang', 'gcc', 'cc'];
    for (const compiler of compilers) {
      try {
        execSync(`which ${compiler}`, { stdio: 'ignore' });
        cc = compiler;
        break;
      } catch (e) {
        // 继续尝试下一个编译器
      }
    }
  } catch (e) {
    // 使用默认的 cc
  }

  // 检查环境变量
  const readlineRoot = process.env.READLINE_ROOT;
  const readlineInclude = process.env.READLINE_INCLUDE_PATH;
  const readlineLib = process.env.READLINE_LIB_PATH;
  
  if (readlineRoot || (readlineInclude && readlineLib)) {
    if (readlineRoot) {
      const includePath = path.join(readlineRoot, 'include');
      const libPath = path.join(readlineRoot, 'lib');
      
      if (fs.existsSync(path.join(includePath, 'readline', 'readline.h'))) {
        ccFlags.push(`-I${includePath}`);
        ccLinkFlags.push(`-L${libPath}`, '-lreadline', '-lncurses');
      }
    } else {
      if (fs.existsSync(path.join(readlineInclude, 'readline', 'readline.h'))) {
        ccFlags.push(`-I${readlineInclude}`);
        ccLinkFlags.push(`-L${readlineLib}`, '-lreadline', '-lncurses');
      }
    }
  }
  
  if (platform === 'darwin') {
    // macOS
    
    // 首先尝试使用 pkg-config
    try {
      const cflags = execSync('pkg-config --cflags readline', { encoding: 'utf8' }).trim();
      const libs = execSync('pkg-config --libs readline', { encoding: 'utf8' }).trim();
      
      if (cflags) ccFlags.push(...cflags.split(/\s+/).filter(f => f.trim()));
      if (libs) ccLinkFlags.push(...libs.split(/\s+/).filter(f => f.trim()));
    } catch (e) {
      // 首先尝试检测 Homebrew keg-only 安装
      let homebrewPrefix = null;
      try {
        homebrewPrefix = execSync('brew --prefix', { encoding: 'utf8' }).trim();
      } catch (e) {
        // brew 命令不存在，忽略
      }
      
      const possiblePaths = [
        '/opt/homebrew',     // Apple Silicon Homebrew
        '/usr/local',        // Intel Homebrew
        '/opt/local',        // MacPorts
        '/usr'               // 系统默认
      ];
      
      // 如果找到了 homebrew，也加入 readline 的 keg-only 路径
      if (homebrewPrefix) {
        try {
          const readlinePrefix = execSync('brew --prefix readline', { encoding: 'utf8' }).trim();
          if (readlinePrefix) {
            possiblePaths.unshift(readlinePrefix);
          }
        } catch (e) {
          // readline 包可能没安装，忽略
        }
      }
      
      for (const basePath of possiblePaths) {
        const includePath = path.join(basePath, 'include');
        const libPath = path.join(basePath, 'lib');
        const readlineHeader = path.join(includePath, 'readline', 'readline.h');
        
        if (fs.existsSync(readlineHeader)) {
          ccFlags.push(`-I${includePath}`);
          
          // 检查库文件
          const libReadline = path.join(libPath, 'libreadline.dylib');
          const libReadlineA = path.join(libPath, 'libreadline.a');
          
          if (fs.existsSync(libReadline) || fs.existsSync(libReadlineA)) {
            ccLinkFlags.push(`-L${libPath}`, '-lreadline');
            
            // 检查 history 库
            const libHistory = path.join(libPath, 'libhistory.dylib');
            const libHistoryA = path.join(libPath, 'libhistory.a');
            if (fs.existsSync(libHistory) || fs.existsSync(libHistoryA)) {
              ccLinkFlags.push('-lhistory');
            }
            
            // 在 macOS 上，readline 通常需要 ncurses
            const libNcurses = path.join(libPath, 'libncurses.dylib');
            const libNcursesA = path.join(libPath, 'libncurses.a');
            if (fs.existsSync(libNcurses) || fs.existsSync(libNcursesA)) {
              ccLinkFlags.push('-lncurses');
            }
            
            break;
          }
        }
      }
      
      // 如果仍然没有找到，使用 mock 实现
      if (ccFlags.length === 0 && ccLinkFlags.length === 0) {
        // 使用 mock 实现
        useMockImplementation = true;
        // mock 实现不需要链接外部库
        ccLinkFlags = [];
      }
    }
    
  } else if (platform === 'linux') {
    // Linux
    
    const possiblePaths = [
      '/usr',
      '/usr/local',
      '/opt/local'
    ];
    
    for (const basePath of possiblePaths) {
      const includePath = path.join(basePath, 'include');
      const libPath = path.join(basePath, 'lib');
      const readlineHeader = path.join(includePath, 'readline', 'readline.h');
      
      if (fs.existsSync(readlineHeader)) {
        ccFlags.push(`-I${includePath}`);
        
        // 检查多个可能的 lib 目录
        const libDirs = [
          libPath,
          path.join(basePath, 'lib', 'x86_64-linux-gnu'),
          path.join(basePath, 'lib64')
        ];
        
        for (const libDir of libDirs) {
          const libReadline = path.join(libDir, 'libreadline.so');
          const libReadlineA = path.join(libDir, 'libreadline.a');
          
          if (fs.existsSync(libReadline) || fs.existsSync(libReadlineA)) {
            ccLinkFlags.push(`-L${libDir}`, '-lreadline');
            
            // Linux 上 readline 通常需要 ncurses
            const libNcurses = path.join(libDir, 'libncurses.so');
            const libNcursesA = path.join(libDir, 'libncurses.a');
            if (fs.existsSync(libNcurses) || fs.existsSync(libNcursesA)) {
              ccLinkFlags.push('-lncurses');
            }
            
            break;
          }
        }
        break;
      }
    }
    
    // 如果没有找到，尝试使用 pkg-config
    if (ccFlags.length === 0) {
      try {
        const cflags = execSync('pkg-config --cflags readline', { encoding: 'utf8' }).trim();
        const libs = execSync('pkg-config --libs readline', { encoding: 'utf8' }).trim();
        
        if (cflags) ccFlags.push(...cflags.split(/\s+/));
        if (libs) ccLinkFlags.push(...libs.split(/\s+/));
      } catch (e) {
        ccLinkFlags.push('-lreadline', '-lncurses');
      }
    }
    
  } else if (platform === 'win32') {
    // Windows
    
    // Windows 上通常使用 MSYS2 或者其他包管理器
    const possiblePaths = [
      'C:\\msys64\\mingw64',
      'C:\\msys64\\usr',
      'C:\\MinGW',
      'C:\\tools\\msys64\\mingw64'
    ];
    
    for (const basePath of possiblePaths) {
      const includePath = path.join(basePath, 'include');
      const libPath = path.join(basePath, 'lib');
      const readlineHeader = path.join(includePath, 'readline', 'readline.h');
      
      if (fs.existsSync(readlineHeader)) {
        ccFlags.push(`-I${includePath}`);
        
        const libReadline = path.join(libPath, 'libreadline.a');
        if (fs.existsSync(libReadline)) {
          ccLinkFlags.push(`-L${libPath}`, '-lreadline', '-lncurses');
          break;
        }
      }
    }
    
    if (ccFlags.length === 0) {
      ccLinkFlags.push('-lreadline', '-lncurses');
    }
    
  } else {
    // 其他平台
    ccLinkFlags.push('-lreadline', '-lncurses');
  }
  
  // 确保至少有基本的链接标志（除非使用 mock 实现）
  if (ccLinkFlags.length === 0 && !useMockImplementation) {
    ccLinkFlags.push('-lreadline', '-lncurses');
  }
  
  return {
    cc,
    ccFlags: ccFlags.join(' '),
    ccLinkFlags: ccLinkFlags.join(' '),
    useMockImplementation
  };
}

/**
 * 生成包配置
 */
function generatePackageConfig() {
  const config = detectReadlineConfig();
  
  // 添加 -std=c99 到 cc-flags
  let ccFlags = config.ccFlags;
  if (ccFlags && ccFlags.trim() && !ccFlags.includes('-std=c99')) {
    ccFlags = ccFlags.trim() + ' -std=c99';
  } else if (!ccFlags || !ccFlags.trim()) {
    ccFlags = '-std=c99';
  }
  
  const packageConfig = {         
    "link_configs": [{          
        "package": "allwefantasy/readline.mbt/lib",  
        "flags": ccFlags,
        "link_flags": config.ccLinkFlags
      }
    ]
  };
  
  // 输出配置给 moon 构建系统
  console.log(JSON.stringify(packageConfig, null, 2));
}

// 主程序
if (require.main === module) {
  try {
    generatePackageConfig();
  } catch (error) {
    process.exit(1);
  }
}
