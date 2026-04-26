// 魔宝盒测试爬虫脚本
// 用于演示和测试爬虫引擎功能

var initialized = false;

// 初始化
function init(params) {
    console.log('Spider init: ' + params);
    initialized = true;
    return JSON.stringify({code: 200, msg: '初始化成功'});
}

// 首页分类
function home(params) {
    console.log('Home called with: ' + params);
    
    var result = {
        "class": [
            {"type_id": "1", "type_name": "电影"},
            {"type_id": "2", "type_name": "电视剧"},
            {"type_id": "3", "type_name": "动漫"},
            {"type_id": "4", "type_name": "综艺"}
        ],
        "filters": {
            "1": [
                {
                    "key": "year",
                    "name": "年份",
                    "value": [
                        {"n": "全部", "v": ""},
                        {"n": "2024", "v": "2024"},
                        {"n": "2023", "v": "2023"}
                    ]
                }
            ]
        }
    };
    
    return JSON.stringify(result);
}

// 分类列表
function category(params) {
    console.log('Category called with: ' + params);
    
    var p = JSON.parse(params || '{}');
    var tid = p.tid || '1';
    var page = p.page || '1';
    var filter = p.filter || false;
    var extend = p.extend || '';
    
    // 生成测试数据
    var list = [];
    var start = (parseInt(page) - 1) * 20 + 1;
    
    for (var i = 0; i < 20; i++) {
        list.push({
            "vod_id": tid + "_" + (start + i),
            "vod_name": "视频" + (start + i),
            "type_name": tid == '1' ? "电影" : tid == '2' ? "电视剧" : "动漫",
            "vod_pic": "https://via.placeholder.com/300x450/333333/ffffff?text=Video" + (start + i),
            "vod_remarks": "第" + (i + 1) + "集",
            "vod_year": "2024",
            "vod_area": "中国"
        });
    }
    
    var result = {
        "list": list,
        "page": parseInt(page),
        "pagecount": 10,
        "limit": 20,
        "total": 200
    };
    
    return JSON.stringify(result);
}

// 详情
function detail(params) {
    console.log('Detail called with: ' + params);
    
    var p = JSON.parse(params || '{}');
    var id = p.id || '';
    
    var result = {
        "list": [{
            "vod_id": id,
            "vod_name": "测试视频 " + id,
            "type_name": "电影",
            "vod_pic": "https://via.placeholder.com/300x450/333333/ffffff?text=Video",
            "vod_remarks": "HD",
            "vod_year": "2024",
            "vod_area": "中国",
            "vod_director": "张三",
            "vod_actor": "李四，王五",
            "vod_content": "这是一个测试视频的简介内容",
            "vod_play_from": "测试线路",
            "vod_play_url": "第1集$http://example.com/video1.mp4#第2集$http://example.com/video2.mp4#第3集$http://example.com/video3.mp4"
        }]
    };
    
    return JSON.stringify(result);
}

// 播放
function play(params) {
    console.log('Play called with: ' + params);
    
    var p = JSON.parse(params || '{}');
    var flag = p.flag || '';
    var id = p.id || '';
    
    // 返回播放地址
    var result = {
        "parse": 0,
        "url": "http://example.com/video.mp4",
        "header": {
            "User-Agent": "Mozilla/5.0"
        }
    };
    
    return JSON.stringify(result);
}

// 搜索
function search(params) {
    console.log('Search called with: ' + params);
    
    var p = JSON.parse(params || '{}');
    var wd = p.wd || '';
    var quick = p.quick || false;
    
    // 生成搜索结果
    var list = [];
    for (var i = 0; i < 10; i++) {
        list.push({
            "vod_id": "search_" + i,
            "vod_name": wd + " 搜索结果" + i,
            "type_name": "电影",
            "vod_pic": "https://via.placeholder.com/300x450/333333/ffffff?text=Search" + i,
            "vod_remarks": "HD",
            "vod_year": "2024"
        });
    }
    
    var result = {
        "list": list
    };
    
    return JSON.stringify(result);
}

// 销毁
function destroy() {
    console.log('Spider destroyed');
    initialized = false;
}
