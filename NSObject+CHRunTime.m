//
//  NSObject+CHRunTime.m
//  ITNewsApp
//
//  Created by CrazyHacker on 16/6/12.
//  Copyright © 2016年 CrazyHacker. All rights reserved.
//

#import "NSObject+CHRunTime.h"
#import <objc/runtime.h>

@implementation NSObject (CHRunTime)

#pragma mark - 根据传递进来的所有字典数组 字典转模型
+ (NSArray *)ch_objectsWithArray:(NSArray *)array {
    if (array.count == 0) {
        return nil;
    }
    
    // 判断是否是字典数组
    NSAssert([array[0] isKindOfClass:[NSDictionary class]], @"必须传入字典数组");
    
    // 获取属性列表数组
    NSArray *propertyList = [self ch_propertysList];
    
    NSMutableArray *arrayM = [NSMutableArray array];
  
    for (NSDictionary *dict in array) {
        // 创建模型
        id model = [self new];
        
        // 遍历数组
        for (NSString *key in dict) {
            
            // 判断属性列表数组中是否包含当前key 如果有, 意味着属性存在
            if ([propertyList containsObject:key]) {
                // 字典转模型
                [model setValue:dict[key] forKey:key];
            }
        }
        // 添加到可变数组中
        [arrayM addObject:model];
    }
    return arrayM.copy;
}

#pragma mark - 获取本类所有 ‘属性‘ 的数组
/** 程序运行的时候动态的获取当前类的属性列表 
 *  程序运行的时候,类的属性不会变化
 */
    const void *ch_propertyListKey = @"ch_propertyListKey";
+ (NSArray *)ch_propertysList {
    NSArray *result = objc_getAssociatedObject(self, ch_propertyListKey);
    
    if (result != nil) {
        return result;
    }
    
    NSMutableArray *arrayM = [NSMutableArray array];
    // 获取当前类的属性数组
    // count -> 属性的数量
    unsigned int count = 0;
   objc_property_t *list = class_copyPropertyList([self class], &count);
    
    for (unsigned int i = 0; i < count; i++) {
        // 根据下标获取属性
        objc_property_t property = list[i];
        
        // 获取属性的名字
        const char *cName = property_getName(property);
        
        // 转换成OC字符串
        NSString *name = [NSString stringWithUTF8String:cName];
        [arrayM addObject:name];
    }
    
    // ⚠️注意： 一定要释放数组
    free(list);
    
    // ---保存属性数组对象---
    objc_setAssociatedObject(self, ch_propertyListKey, arrayM, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    return objc_getAssociatedObject(self, ch_propertyListKey);
}

#pragma mark - 获取本类所有 ‘方法‘ 的数组
 const void *ch_methodListKey = "ch_methodListKey";
+ (NSArray *)ch_methodList {
    
    // 1. 使用运行时动态添加属性
    NSArray *methodsList = objc_getAssociatedObject(self, ch_methodListKey);
    
    // 2. 如果数组中直接返回方法数组
    if (methodsList != nil) {
        return methodsList;
    }
    
    // 3. 获取当前类的方法数组
    unsigned int count = 0;
    Method *list = class_copyMethodList([self class], &count);
    
    NSMutableArray *arrayM = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        // 根据下标获取方法
        Method method = list[i];
        
       SEL methodName = method_getName(method);
        
        NSString *methodName_OC = NSStringFromSelector(methodName);
        
        [arrayM addObject:methodName_OC];
    }
    
    // 4. 释放数组
    free(list);
    
    // 5. 保存方法的数组对象
    objc_setAssociatedObject(self, ch_methodListKey, arrayM, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    return objc_getAssociatedObject(self, ch_methodListKey);
}


#pragma mark - 获取本类所有 ‘成员变量‘ 的数组 <用来调试>
/** 获取当前类的所有成员变量 */
 const char *ch_ivarListKey = "ch_ivarListKey";
+ (NSArray *)ch_ivarList {
   
    // 1. 查询根据key 保存的成员变量数组
    NSArray *ivarList = objc_getAssociatedObject(self, ch_ivarListKey);
    
    // 2. 判断数组中是否有值, 如果有直接返回
    if (ivarList != nil) {
        return ivarList;
    }
    
    // 3. 如果数组中没有, 则根据当前类,获取当前类的所有 ‘成员变量‘
    unsigned int count = 0;
  Ivar *ivars = class_copyIvarList([self class], &count);
    
    // 4. 遍历 成员变量 数组, 获取成员变量的名
    NSMutableArray *arrayM = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        // - C语言的字符串都是 ‘char *‘ 类型的
        const char *ivarName_C = ivar_getName(ivar);
        
        // - 将 C语言的字符串 转换成 OC字符串
        NSString *ivarName_OC = [NSString stringWithUTF8String:ivarName_C];
        // - 将本类 ‘成员变量名‘ 添加到数组
        [arrayM addObject:ivarName_OC];
    }
    
    // 5. 释放ivars
    free(ivars);
    
    // 6. 根据key 动态获取保存在关联对象中的数组
    objc_setAssociatedObject(self, ch_ivarListKey, arrayM, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    return objc_getAssociatedObject(self, ch_ivarListKey);
}

#pragma mark - 获取本类所有 ‘协议‘ 的数组
/** 用来获取动态保存在关联对象中的协议数组 |运行时的关联对象根据key动态取值| */
const char *ch_protocolListKey = "ch_protocolListKey";
+ (NSArray *)ch_protocolList {
    NSArray *protocolList = objc_getAssociatedObject(self, ch_protocolListKey);
    if (protocolList != nil) {
        return protocolList;
    }
    
    unsigned int count = 0;
    Protocol * __unsafe_unretained *protocolLists = class_copyProtocolList([self class], &count);
    
    NSMutableArray *arrayM = [NSMutableArray array];
    for (unsigned int i = 0; i < count; i++) {
        // 获取 协议名
        Protocol *protocol = protocolLists[i];
        const char *protocolName_C = protocol_getName(protocol);
        NSString *protocolName_OC = [NSString stringWithUTF8String:protocolName_C];
        
        // 将 协议名 添加到数组
        [arrayM addObject:protocolName_OC];
    }
    
    // 释放数组
    free(protocolLists);
    // 将保存 协议的数组动态添加到 关联对象
    objc_setAssociatedObject(self, ch_protocolListKey, arrayM, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    return objc_getAssociatedObject(self, ch_protocolListKey);
}
@end
