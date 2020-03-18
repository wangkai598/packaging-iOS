#!/bin/bash
currentpwd=$(pwd)
user=$(whoami)
dingtalkApi="https://oapi.dingtalk.com/robot/send?access_token=xxxx"
 #echo $user
 if [ ! -d "/Users/$user/OSSCMD" ]; then
    echo "osscmd 未安装"
    echo "开始安装osscmd"
 brew install wget
wget -P ~/ https://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/internal/oss/0.0.4/assets/sdk/OSS_Python_API_20160419.zip

cd ~/
mkdir OSSCMD
cd  OSSCMD
unzip ~/OSS_Python_API_20160419.zip 
sudo python setup.py install
sudo ln -s `pwd`/osscmd /usr/local/bin/osscmd
 osscmd config --host=oss-cn-beijing.aliyuncs.com --id=xxxx --key=xxxx 
echo "pythonosscmd 安装完成"
chomd +x ./picaDoBuild.sh 
   else
   echo "pythonosscmd已经安装"
   fi
cd $currentpwd

trap 'onCtrlC' INT
function onCtrlC () {
echo 'Ctrl+C is captured'
curl "$dingtalkApi" \
     -H 'Content-Type: application/json' \
     -d '{
             "msgtype": "text",
              "text": {
                  "content": "😌打包中止。\n上   传: '$user'    "              },
              "at": {
                  "isAtAll": true
              }
         }'
exit
}


INFOPLIST=PicaDo/Info.plist
startTime=`date +%Y%m%d-%H:%M`
startTime_s=`date +%s`
echo "--开始clean--"
xcodebuild clean -workspace PicaDo.xcworkspace -scheme PicaDo -configuration Debug
echo "--开始下载导出plist--"
osscmd get oss://xxxx/Ios/Export.plist ./Export.plist
echo "--开始打包--"
xcodebuild archive -workspace PicaDo.xcworkspace -scheme PicaDo -archivePath ~/Desktop/PicaDo/PicaDo.xcarchive
xcodebuild -exportArchive -exportOptionsPlist Export.plist -archivePath ~/Desktop/PicaDo/PicaDo.xcarchive -exportPath ~/Desktop/PicaDo/autoPackage

if [ $? -ne 0 ]; then
    echo "failed"
curl "$dingtalkApi" \
       -H 'Content-Type: application/json' \
       -d '{
               "msgtype": "text",
                "text": {
                    "content": "😭打包失败。\n上   传: '$user'    "              },
                "at": {
                    "isAtAll": true
                }
           }'   
exit
else
    echo "succeed"
fi

echo "--打包完成--"
echo "--开始上传--"
 #BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $INFOPLIST)
 BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :objects:5A2B76E01D75565B004C3428:buildSettings:MARKETING_VERSION" ./PicaDo.xcodeproj/project.pbxproj)
echo "当前打包版本:$BUILD_VERSION"
echo "--开始下载test.plist"
osscmd get oss://xxx/Ios/test.plist ./test.plist
echo "--下载test.plist完成--"
/usr/libexec/PlistBuddy -c "Set :items:0:"assets":0:"url" "https://pica-test-huabei2.oss-cn-beijing.aliyuncs.com/Ios/$BUILD_VERSION/PicaDo.ipa"" ./test.plist
osscmd put ./test.plist oss://xxx/Ios/tmp/$BUILD_VERSION/test.plist
echo "上传tmp完成"
osscmd put ./test.plist  oss://xxxx/Ios/$BUILD_VERSION/test.plist
osscmd put ~/Desktop/PicaDo/autoPackage/PicaDo.ipa  oss://pica-test-huabei2/Ios/$BUILD_VERSION/PicaDo.ipa
echo "开始生成html下载页面"
osscmd downloadallobject oss://pica-test-huabei2/Ios/tmp/ ./tmp 
osscmd get oss://xxxx/Ios/html.py ./html.py
python html.py
osscmd put ./index.html oss://xxxx/Ios/index.html
echo "下载页面更新成功"
rm -rf  ./html.py
rm -rf ./test.plist
rm -rf ./tmp
rm -rf ./index.html
rm -rf ./Export.plist
echo "开始合并生成包"
cd ~/Desktop/PicaDo/
DATE=$(date +%Y-%m-%d_%H:%M:%S)
mkdir $DATE
mv ./PicaDo.xcarchive/ ./$DATE
mv autoPackage ./$DATE
echo "合并完成"
echo "开始生成二维码"
osscmd get oss://xxxx/Ios/testqrcode.png ~/Desktop/PicaDo/testqrcode.png
echo "前往桌面PicaDo查看所有信息"  
echo "上传完成"

endTime=`date +%Y%m%d-%H:%M`

endTime_s=`date +%s`

sumTime=$[ $endTime_s - $startTime_s ]

useTime=$[ $sumTime / 60 ]

echo "$startTime ---> $endTime" "Totl:$useTime minutes"

echo "钉钉机器人发送消息"
curl "$dingtalkApi" \
   -H 'Content-Type: application/json' \
   -d '{
            "msgtype": "text", 
            "text": {
                "content": "😎打包好了😜👍👌✌️🖐💪大家测试一下。\n版   本: '$BUILD_VERSION'\n用   时: '$sumTime's\n上   传: '$user'\n上传时间: '$endTime'    "
            },
            "at": {
                "isAtAll": true
            }
        }'



