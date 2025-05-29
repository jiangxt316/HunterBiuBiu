# HunterBiuBiu
Turtle-WoW Marksmanship Hunter Addon

## 本人非作者，感谢大佬制作此插件。如有侵权，请联络删除。

## 一些实用的宏（部分需要安装SuperMacro/RoidMacro等插件）

### 一键输出宏

##### /script if not buffed("雄鹰守护") then CastSpellByName("雄鹰守护") end;
##### /script if not buffed("强击光环") then CastSpellByName("强击光环") end;
##### /script HbbShot()
##### /script local t,m,f,a,b,c,d=GetTime(),UnitMana("pet"),function(i,b) if ({GetPetActionInfo(i)})[7]~=b then TogglePetAutocast(i) end end; for i=1,10 do c=GetPetActionInfo(i) or ''; if c=='撕咬' then a=i elseif c=='爪击' then b=i end end if a and b then f(a,1)f(b) d=GetPetActionCooldown(a) if m >=70 or (t-d<2 and m >=45) then CastPetAction(b) end end

#### 特点：
1.自动补雄鹰守护和强击光环
2.不使用防止抽筋按宏怪死后BB冲向下一波怪
3.自动控制BB的撕咬和爪击保证集中值优先放撕咬
4.依赖hbb插件，实现稳固射击不吞平射
备注：需要HunterBiuBiu


### 钉刺宏

###### /script if not FindBuff("毒蛇钉刺","target") then cast("毒蛇钉刺");end

#### 特点：
如果对方身上有钉刺，则无动作，无钉刺自动补钉刺。考虑元素怪很多免疫钉刺，所以没放在主宏里

### 减速宏

##### /script CastSpellByName("摔绊"); 
##### /script CastSpellByName("震荡射击"); 

### 宝宝宏

##### /run p='pet'c,h=CastSpellByName,UnitHealth(p)if h==0 then c('召唤宠物')c('复活宠物')elseif h/UnitHealthMax(p)<1 then c('治疗宠物')elseif GetPetHappiness()<3 then c('喂养宠物')PickupContainerItem(0,1)else c('解散野兽')end 

#### 特点：
1.没宝宝召唤宝宝
2.宝宝死了复活宝宝
3.不开心喂宝宝（把肉放在背包第1格）
4.解散宝宝

### 坐骑猎豹整合宏：

##### /cast 骑乘乌龟
##### /script if not buffed("猎豹守护") then CastSpellByName("猎豹守护") end;
