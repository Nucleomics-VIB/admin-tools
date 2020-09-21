<!--
 // author: Stéphane Plaisance, VIB-NC, 2020-07-20
 // script: 'create_project_folder_onL.php'
 // runs: 'create_project_folder_onL.sh'
 // links to: 'create_project_folder_onL_done.php'
 // version 1.0.0
 // visit our Git: https://github.com/Nucleomics-VIB
-->

<html>
 <head>
  <title>Folder Created</title>
 </head>
 <body>

 <?php
 session_start();
 echo '<h2>Project Folder was created on L:</h2>';
 echo '<h3>Result: ' . $_SESSION['result'] . '</h3>';

 // extract Foldername
 $subject = $_SESSION['result'];
 $pattern = '/[0-9]+_[A-Z0-9a-z_-]+/m';
 if (preg_match($pattern, $subject, $match)){
   $foldername=$match[0];
   $path = '/mnt/nuc-data/Projects/' . $foldername;
   echo '<p>Folder structure of: <b>' . $foldername . '</b></p>';
   // list folder content
   if (is_dir($path)) {
     echo '<ul>';
     $files=scandir($path);
     $content = array_diff(scandir($path), array('..', '.'));
     foreach($content as $file){
       echo '<li> ' . $file . ' </li>';
       }
     }
   echo '</ul>';
 }
 ?>

 <?php echo '<p><a href=http://10.112.84.39/cgi-bin/create_project_folder_onL.php>Create another Project folder</a></p>'; ?>
 <?php echo '<p><a href=http://10.112.84.39/portal/>Return to NC Portal</a></p>'; ?>

 </body>
</html>
