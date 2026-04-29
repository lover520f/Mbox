// TVBox JS Spider 测试脚本
// 用于验证爬虫系统是否正常工作

var Spider = {
    init: function (extend) {
        console.log('JS Spider init: ' + extend);
        return true;
    },
    
    home: function (filter) {
        console.log('JS Spider home: filter=' + filter);
        var result = {
            'class': [
                {'type_id': '1', 'type_name': '电影'},
                {'type_id': '2', 'type_name': '电视剧'},
                {'type_id': '3', 'type_name': '综艺'},
                {'type_id': '4', 'type_name': '动漫'}
            ],
            'filters': {}
        };
        return JSON.stringify(result);
    },
    
    category: function (params) {
        console.log('JS Spider category: ' + JSON.stringify(params));
        var tid = params.tid;
        var pg = params.page || 1;
        var filter = params.filter || false;
        var result = {
            'list': [
                {
                    'vod_id': 'test_' + tid + '_' + pg,
                    'vod_name': '测试视频_' + tid + '_' + pg,
                    'type_name': '测试分类',
                    'vod_pic': 'https://via.placeholder.com/300x450',
                    'vod_remarks': 'HD',
                    'vod_year': '2024',
                    'vod_area': '中国',
                    'vod_director': '测试导演',
                    'vod_actor': '测试演员',
                    'vod_content': '这是一个测试视频的简介',
                    'vod_play_from': 'test',
                    'vod_play_url': '第 1 集$http://example.com/video1.mp4#第 2 集$http://example.com/video2.mp4'
                }
            ],
            'page': parseInt(pg),
            'pagecount': 10,
            'limit': 20,
            'total': 200
        };
        return JSON.stringify(result);
    },
    
    detail: function (params) {
        console.log('JS Spider detail: ' + JSON.stringify(params));
        var id = params.id;
        var result = {
            'list': [
                {
                    'vod_id': id,
                    'vod_name': '测试视频详情_' + id,
                    'type_name': '测试分类',
                    'vod_pic': 'https://via.placeholder.com/300x450',
                    'vod_remarks': 'HD',
                    'vod_year': '2024',
                    'vod_area': '中国',
                    'vod_director': '测试导演',
                    'vod_actor': '测试演员',
                    'vod_content': '这是一个测试视频的简介',
                    'vod_play_from': 'test',
                    'vod_play_url': '第 1 集$http://example.com/video1.mp4#第 2 集$http://example.com/video2.mp4#第 3 集$http://example.com/video3.mp4'
                }
            ]
        };
        return JSON.stringify(result);
    },
    
    play: function (params) {
        console.log('JS Spider play: ' + JSON.stringify(params));
        var flag = params.flag;
        var id = params.id;
        var vipFlags = params.vipFlags || '';
        
        // 返回播放地址
        var result = {
            'parse': 0,
            'url': 'http://example.com/video.mp4',
            'header': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        };
        return JSON.stringify(result);
    },
    
    search: function (params) {
        console.log('JS Spider search: ' + JSON.stringify(params));
        var wd = params.wd;
        var quick = params.quick || false;
        var result = {
            'list': [
                {
                    'vod_id': 'search_' + wd,
                    'vod_name': '搜索结果：' + wd,
                    'type_name': '测试分类',
                    'vod_pic': 'https://via.placeholder.com/300x450',
                    'vod_remarks': 'HD'
                }
            ]
        };
        return JSON.stringify(result);
    },
    
    destroy: function () {
        console.log('JS Spider destroyed');
        return true;
    }
};

// 全局函数包装
function home(filter) { return Spider.home(filter); }
function category(params) { return Spider.category(params); }
function detail(params) { return Spider.detail(params); }
function play(params) { return Spider.play(params); }
function search(params) { return Spider.search(params); }
function init(extend) { return Spider.init(extend); }
function destroy() { return Spider.destroy(); }
