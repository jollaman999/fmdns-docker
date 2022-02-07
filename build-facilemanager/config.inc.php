<?php

/**
 * Contains configuration details for facileManager
 *
 * @package facileManager
 *
 */

/** Database credentials */
$__FM_CONFIG['db']['host'] = getenv('MYSQL_HOST') ?: 'localhost';
$__FM_CONFIG['db']['user'] = getenv('MYSQL_USERNAME') ?: 'root';
$__FM_CONFIG['db']['pass'] = getenv('MYSQL_PASSWORD') ?: '';
$__FM_CONFIG['db']['name'] = getenv('MYSQL_DATABASE_NAME') ?: 'facileManager';

require_once(ABSPATH . 'fm-modules/facileManager/functions.php');

?>
